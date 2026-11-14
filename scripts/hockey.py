#!/usr/bin/env python3
"""Read-only Swehockey team fixtures; no inference about player ice time."""

import argparse
from datetime import datetime, timezone
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import urllib.error
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo

BASE = "https://stats.swehockey.se"
STOCKHOLM = ZoneInfo("Europe/Stockholm")
LIMIT = 2 * 1024 * 1024


def official_url(value):
    url = urllib.parse.urljoin(BASE, value)
    parsed = urllib.parse.urlsplit(url)
    if (parsed.scheme != "https" or parsed.netloc != "stats.swehockey.se"
            or parsed.query or parsed.fragment
            or not re.fullmatch(r"/(?:ScheduleAndResults/Schedule|Teams/Info/TeamRoster|Game/(?:Events|LineUps))/[0-9]+", parsed.path)):
        raise ValueError("not an allowed public Swehockey endpoint")
    return url


class Redirects(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return super().redirect_request(req, fp, code, msg, headers, official_url(newurl))


class Sources:
    def __init__(self):
        self.coverage = []
        self.cache = {}
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), Redirects())

    def get(self, url):
        url = official_url(url)
        if url not in self.cache:
            entry = {"url": url, "retrieved_at": datetime.now(timezone.utc).isoformat()}
            self.coverage.append(entry)
            try:
                if len(self.coverage) > 64:
                    raise ValueError("request budget exceeded (64)")
                req = urllib.request.Request(url, headers={"User-Agent": "hockey-cli/1.0", "Cache-Control": "no-cache"})
                with self.opener.open(req, timeout=15) as response:
                    official_url(response.url)
                    if response.headers.get_content_type() != "text/html":
                        raise ValueError("expected HTML")
                    data = response.read(LIMIT + 1)
                    if len(data) > LIMIT:
                        raise ValueError("HTML exceeds 2 MiB")
                    self.cache[url] = data.decode("utf-8-sig")
                entry["status"] = "ok"
            except (OSError, ValueError, urllib.error.URLError) as exc:
                entry.update(status="unavailable", error=str(exc))
                self.cache[url] = None
        if self.cache[url] is None:
            raise OSError("source unavailable: " + url)
        return self.cache[url]


class Node:
    def __init__(self, tag="", attrs=()):
        self.tag, self.attrs, self.children = tag, dict(attrs), []

    def text(self):
        return " ".join(" ".join(c.text() if isinstance(c, Node) else c for c in self.children).split())

    def find(self, tag):
        for child in self.children:
            if isinstance(child, Node):
                if child.tag == tag:
                    yield child
                yield from child.find(tag)


class Document(HTMLParser):
    def __init__(self, source):
        super().__init__(convert_charrefs=True)
        self.root = Node()
        self.stack = [self.root]
        self.closed = False
        self.feed(source)
        self.close()
        if not self.closed or len(self.stack) != 1:
            raise ValueError("truncated or unbalanced HTML")

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"}:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if self.stack[-1].tag == tag:
            self.stack.pop()

    def handle_endtag(self, tag):
        if self.stack[-1].tag != tag:
            raise ValueError("unbalanced HTML tag: " + tag)
        self.stack.pop()
        if tag == "html":
            self.closed = True

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def tables(document):
    return [t for t in document.root.find("table") if "tblContent" in t.attrs.get("class", "").split()]


def cells(row):
    return [c for c in row.children if isinstance(c, Node) and c.tag in {"td", "th"}]


def season_check(document, season):
    selected = [o.text() for o in document.root.find("option") if "selected" in o.attrs]
    opened = [c.text() for li in document.root.find("li") if "openItem" in li.attrs.get("class", "").split()
              for c in li.children if isinstance(c, Node) and c.tag == "a"]
    if season not in selected + opened:
        raise ValueError("official page does not select verified season " + season)


def roster(source, mapping, player, season):
    doc = Document(source)
    season_check(doc, season)
    for table in tables(doc):
        rows = list(table.find("tr"))
        if rows and mapping["team"] in [c.text() for c in cells(rows[0])]:
            for row in rows:
                values = [c.text() for c in cells(row)]
                if len(values) >= 3 and values[1:3] == [player["official_name"], player["birth_date"]]:
                    return
    raise ValueError("identity not verified in official team roster: " + mapping["team"])


def local_kickoff(value):
    # Swehockey uses 00:00 for unassigned times; never assert a midnight kickoff.
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}", value) or value.endswith("00:00"):
        return None
    naive = datetime.strptime(value, "%Y-%m-%d %H:%M")
    first = naive.replace(tzinfo=STOCKHOLM, fold=0)
    second = naive.replace(tzinfo=STOCKHOLM, fold=1)
    if first.utcoffset() != second.utcoffset():
        return None  # Ambiguous or nonexistent DST wall time is not a known instant.
    return first.isoformat()


def schedule(source, url, season):
    doc = Document(source)
    season_check(doc, season)
    candidates = [t for t in tables(doc) if list(t.find("h2")) and list(t.find("h2"))[0].text() == "Schedule and Results"]
    if len(candidates) != 1:
        raise ValueError("schedule table missing or ambiguous")
    result = []
    for row in candidates[0].find("tr"):
        fields = cells(row)
        if fields and fields[0].tag == "th":
            continue
        if len(fields) != 7:
            raise ValueError("unrecognized schedule row")
        dates = [n for n in fields[1].find("span") if "lnkTooltip" in n.attrs.get("class", "").split()]
        if len(dates) != 1 or not re.fullmatch(r"[0-9]+", dates[0].attrs.get("title", "")):
            raise ValueError("missing official fixture number")
        pairing, annotation = Node(), Node()
        target = pairing
        for child in fields[2].children:
            if isinstance(child, Node) and child.tag in {"br", "i", "em"}:
                target = annotation
            target.children.append(child)
        teams = re.split(r"\s+-\s+", pairing.text())
        if len(teams) != 2 or not all(teams):
            raise ValueError("unrecognized team pairing")
        date_text, score = dates[0].text(), fields[3].text()
        links = []
        for a in fields[3].find("a"):
            href = a.attrs.get("href", "").strip()
            emitted = re.fullmatch(r"javascript:openonlinewindow\('(/Game/Events/[0-9]+)',''\)", href)
            links.append(official_url(emitted[1] if emitted else href))
        if len(set(links)) > 1:
            raise ValueError("conflicting match links")
        marker = (date_text + " " + score + " " + annotation.text()).casefold()
        status = "scheduled"
        if re.search(r"instäl|cancel", marker):
            status = "cancelled"
        elif re.search(r"postpon|uppskjut|flytt", marker):
            status = "postponed"
        elif re.fullmatch(r"\d+\s*-\s*\d+", score):
            status = "result_reported"
        elif score or annotation.text():
            status = "unknown"
        result.append({"fixture_id": dates[0].attrs["title"], "home": teams[0], "away": teams[1],
                       "date": date_text[:10] if re.match(r"\d{4}-\d{2}-\d{2}", date_text) else None,
                       "kickoff": local_kickoff(date_text), "time_text": date_text,
                       "venue": fields[6].text() or None, "status": status, "status_text": annotation.text() or None,
                       "source_url": url, "match_url": links[0] if links else None})
    if not result:
        raise ValueError("empty schedule: coverage cannot be established")
    return result


def lineup(source, fixture, team, name):
    doc = Document(source)
    verify_game(doc, fixture)
    if "Line Up" not in [h.text() for h in doc.root.find("h2")]:
        raise ValueError("lineup heading missing")
    active_team, names = None, []
    for table in tables(doc):
        # Only the innermost team table; outer tables contain the same players.
        if any("lineUpPlayer" in n.attrs.get("class", "").split() for n in table.find("div")) and not any(
                "lineUpPlayer" in n.attrs.get("class", "").split() for t in table.find("table") for n in t.find("div")):
            for row in [c for c in table.children if isinstance(c, Node) and c.tag == "tr"]:
                for heading in row.find("h3"):
                    active_team = re.sub(r"\s+\([^)]*\)$", "", heading.text())
                if active_team == team:
                    names.extend(re.sub(r"^\d+\.\s*", "", n.text()).split(" (")[0]
                                 for n in row.find("div") if "lineUpPlayer" in n.attrs.get("class", "").split())
    if not names:
        return "unconfirmed"
    return "listed" if name in names else "not_listed"


def verify_game(doc, fixture):
    headings = [h.text() for h in doc.root.find("h2")]
    dates = [h.text() for h in doc.root.find("h3")]
    if (f'{fixture["home"]} - {fixture["away"]}' not in headings
            or fixture["time_text"] not in dates):
        raise ValueError("match page does not identify fixture teams/date/time")


def participation(sources, fixture, team, name):
    result = {"status": "unconfirmed", "source_url": None, "reason": "no official match link"}
    if not fixture["match_url"]:
        return result
    doc = Document(sources.get(fixture["match_url"]))
    verify_game(doc, fixture)
    links = {official_url(a.attrs["href"]) for a in doc.root.find("a")
             if re.fullmatch(r"/Game/LineUps/[0-9]+", a.attrs.get("href", ""))}
    if not links:
        result["reason"] = "no official lineup link"
        return result
    if len(links) != 1:
        raise ValueError("ambiguous lineup links")
    url = links.pop()
    status = lineup(sources.get(url), fixture, team, name)
    return {"status": status, "source_url": url,
            "reason": "official lineup name/team match; not proof of ice time" if status == "listed"
            else "not in published lineup" if status == "not_listed" else "lineup unavailable or empty"}


def lookup(config, selected, now, sources):
    now = now.astimezone(STOCKHOLM)
    output = {"status": "ok", "checked_at": now.isoformat(), "timezone": "Europe/Stockholm",
              "season": config["season"], "players": [], "sources": sources.coverage}
    for key in selected:
        player = config["players"][key]
        report = {"player": key, "name": player["official_name"], "status": "ok", "errors": [],
                  "checked_teams": [], "today": None, "next": None, "next_candidate": None,
                  "today_status": "unknown", "next_status": "unknown"}
        output["players"].append(report)
        fixtures = {}
        try:
            if not config["valid_from"] <= now.date().isoformat() < config["valid_until"]:
                raise ValueError("season mapping expired/not yet valid; reverify configuration")
            if not player["teams"]:
                raise ValueError("no verified teams configured")
        except ValueError as exc:
            report["errors"].append(str(exc))
        else:
            for mapping in player["teams"]:
                coverage = {"team": mapping["team"], "schedule_url": mapping["schedule"], "status": "unavailable"}
                report["checked_teams"].append(coverage)
                try:
                    roster(sources.get(mapping["roster"]), mapping, player, config["season"])
                    games = schedule(sources.get(mapping["schedule"]), mapping["schedule"], config["season"])
                    matched = [g for g in games if mapping["team"] in (g["home"], g["away"])]
                    if not matched:
                        raise ValueError("configured team missing from schedule")
                    for game in matched:
                        game = dict(game, team=mapping["team"])
                        game["opponent"] = game["away"] if game["home"] == mapping["team"] else game["home"]
                        old = fixtures.get(game["fixture_id"])
                        if old and {k: v for k, v in old.items() if k != "source_url"} != {k: v for k, v in game.items() if k != "source_url"}:
                            raise ValueError("conflicting official fixture " + game["fixture_id"])
                        fixtures[game["fixture_id"]] = game
                    coverage["status"] = "ok"
                except (ValueError, OSError) as exc:
                    coverage.update(status="unavailable" if isinstance(exc, OSError) else "parser_error", error=str(exc))
                    report["errors"].append(str(exc))
        ordered = sorted(fixtures.values(), key=lambda g: (
            datetime.fromisoformat(g["kickoff"]).timestamp() if g["kickoff"] else float("inf"), g["fixture_id"]))
        today = [g for g in ordered if g["date"] == now.date().isoformat()]
        future = [g for g in ordered if g["kickoff"] and datetime.fromisoformat(g["kickoff"]) > now and g["status"] == "scheduled"]
        uncertain = [g for g in ordered if g["status"] != "cancelled"
                     and (not g["date"] or g["date"] >= now.date().isoformat() or g["status"] in {"postponed", "unknown"})
                     and (not g["kickoff"] or g["status"] in {"postponed", "unknown"})]
        complete = not report["errors"]
        if complete and not any(not g["date"] or g["date"] == now.date().isoformat() for g in uncertain):
            report["today"] = today
            report["today_status"] = "ok"
        if complete and not any(not g["date"] or g["status"] == "postponed"
                                or not future or g["date"] <= future[0]["date"] for g in uncertain):
            report["next"] = future[0] if future else None
            report["next_status"] = "ok"
        if uncertain:
            report["errors"].append("unresolved date/time/status: " + ", ".join(g["fixture_id"] for g in uncertain))
        report["unresolved_fixtures"] = uncertain
        report["observed_today"] = today
        report["next_candidate"] = future[0] if future else None
        for game in {g["fixture_id"]: g for g in today + future[:1]}.values():
            try:
                game["participation"] = participation(sources, game, game["team"], player["official_name"])
            except (ValueError, OSError) as exc:
                game["participation"] = {"status": "unconfirmed", "reason": str(exc), "source_url": game["match_url"]}
                report["errors"].append(str(exc))
        if report["errors"]:
            report["status"] = "partial" if fixtures else "unavailable"
    statuses = [p["status"] for p in output["players"]]
    if any(s != "ok" for s in statuses):
        output["status"] = "unavailable" if all(s == "unavailable" for s in statuses) else "partial"
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("players", nargs="*", help="configured keys (default: all)")
    parser.add_argument("--config", type=Path, required=True, help="private runtime JSON path")
    parser.add_argument("--json", action="store_true", help="structured coverage and results")
    args = parser.parse_args()
    try:
        config = json.loads(args.config.read_text())
        selected = list(dict.fromkeys(args.players or config["players"]))
        unknown = set(selected) - config["players"].keys()
        if unknown or not selected:
            raise ValueError("unknown/empty player selection: " + ", ".join(sorted(unknown)))
        result = lookup(config, selected, datetime.now(timezone.utc), Sources())
    except (OSError, ValueError, KeyError, TypeError) as exc:
        result = {"status": "unavailable", "errors": [str(exc)]}
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f'Hockey: {result["status"]} — {result.get("checked_at", "lookup failed")}')
        for player in result.get("players", []):
            print(f'\n{player["name"]}: {player["status"]}')
            displays = [("Today", player["today"]), ("Next", [player["next"]] if player["next"] else None)]
            if player["today"] is None:
                displays.append(("Observed today (not definitive)", player["observed_today"]))
            if player["next"] is None and player["next_candidate"]:
                displays.append(("Next candidate (not definitive)", [player["next_candidate"]]))
            if player["unresolved_fixtures"]:
                displays.append(("Unresolved (not definitive)", player["unresolved_fixtures"]))
            for label, games in displays:
                if games is None:
                    print(f"  {label}: unknown" if player[label.lower() + "_status"] != "ok" else f"  {label}: none in checked schedules")
                elif not games and label == "Today":
                    print(f"  {label}: no team fixture in checked schedules")
                for game in games or []:
                    print(f'  {label}: {game["team"]} vs {game["opponent"]} | {game["kickoff"] or game["time_text"]} | {game["venue"] or "venue unknown"} | {game["status"]}')
                    print(f'    {game["source_url"]} | lineup: {game.get("participation", {}).get("status", "unconfirmed")} (not proof of playing)')
            for error in player["errors"]:
                print("  WARNING: " + error)
            for coverage in player["checked_teams"]:
                print(f'  Checked: {coverage["team"]}: {coverage["status"]} {coverage["schedule_url"]}')
        for error in result.get("errors", []):
            print("ERROR: " + error)
        for source in result.get("sources", []):
            print(f'  Retrieved {source["retrieved_at"]} {source["status"]}: {source["url"]}')
    return 0 if result["status"] == "ok" else 1


if __name__ == "__main__":
    raise SystemExit(main())
