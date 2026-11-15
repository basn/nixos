#!/usr/bin/env python3
"""Read-only Swehockey team fixtures; no inference about player ice time."""

import argparse
import hashlib
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
            link = official_url(emitted[1] if emitted else href)
            if not re.fullmatch(r"/Game/Events/[0-9]+", urllib.parse.urlsplit(link).path):
                raise ValueError("schedule match link is not an Events endpoint")
            links.append(link)
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


def fingerprint(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def match_panel(doc):
    panels = [n for n in doc.root.find("td") if "tdInfoArea" in n.attrs.get("class", "").split()]
    if len(panels) != 1:
        raise ValueError("official match status panel missing or ambiguous")
    texts = [n.text() for n in panels[0].children if isinstance(n, Node) and n.tag == "div"]
    scores = [re.fullmatch(r"(\d+)\s*-\s*(\d+)", t) for t in texts]
    scores = [s for s in scores if s]
    if len(scores) > 1:
        raise ValueError("ambiguous panel score")
    summary = {"status": "unknown", "score": [int(v) for v in scores[0].groups()] if scores else None,
               "period": None, "clock": None, "panel_text": texts}
    if "Final Score" in texts:
        summary["status"] = "final"
    elif any(re.fullmatch(r"Postponed|Uppskjuten", t, re.I) for t in texts):
        summary["status"] = "postponed"
    elif any(re.fullmatch(r"Cancelled|Inställd", t, re.I) for t in texts):
        summary["status"] = "cancelled"
    elif any(re.fullmatch(r"Not started|Scheduled|Waiting for 1st period", t, re.I) for t in texts):
        summary["status"] = "scheduled"
    for text in texts:
        period = re.fullmatch(r"(\d+(?:st|nd|rd|th) (?:period|overtime))(?:\s*[-:]?\s*(\d{1,3}:[0-5]\d))?", text, re.I)
        if period:
            summary.update(period=period[1], clock=period[2])
            if summary["status"] == "unknown":
                summary["status"] = "live"
        elif re.fullmatch(r"\d{1,3}:[0-5]\d", text):
            summary["clock"] = text
    return summary


def event_name(text):
    match = re.fullmatch(r"\d+\.\s+([^()]+?)(?:\s+\([^)]*\))?", " ".join(text.split()))
    return match[1].strip() if match else None


def goal_events(doc, fixture):
    candidates = [t for t in tables(doc) if any(h.text() == "Actions" for h in t.find("h2"))]
    if len(candidates) != 1:
        raise ValueError("Actions table missing or ambiguous")
    events, errors, period = [], [], None
    latest = {"period": None, "time": None}
    for row in candidates[0].find("tr"):
        fields = cells(row)
        headings = [h.text() for h in row.find("h3")]
        if headings:
            period = headings[0] if re.fullmatch(r"\d+(?:st|nd|rd|th) (?:period|overtime)", headings[0], re.I) else None
            continue
        if not fields or fields[0].tag == "th":
            continue
        if len(fields) < 4:
            errors.append("unrecognized Actions row")
            continue
        time, action, team = [f.text() for f in fields[:3]]
        if not time and not action:  # Goalkeeper summary, not an event.
            continue
        valid_time = bool(re.fullmatch(r"\d{1,3}:[0-5]\d", time))
        if not valid_time or period is None:
            errors.append("unrecognized event time/period")
        elif latest["time"] is None or tuple(map(int, time.split(":"))) > tuple(map(int, latest["time"].split(":"))):
            latest = {"period": period, "time": time}
        score = re.fullmatch(r"(\d+)\s*-\s*(\d+)(?:\s*\(([^)]*)\))?", action)
        if not score:
            if re.search(r"\d\s*-\s*\d|goal", action, re.I):
                errors.append("unrecognized scoring action")
            continue
        # Details may be nested inside the player td; only direct text is the scorer.
        scorer = event_name(" ".join(c for c in fields[3].children if isinstance(c, str)))
        assist_nodes = [n for n in fields[3].find("div")
                        if re.search(r"padding-left\s*:\s*10px", n.attrs.get("style", ""))]
        assists = [event_name(n.text()) for n in assist_nodes]
        unexpected = [n for n in fields[3].children if isinstance(n, Node) and not (
            n.tag == "td" or n in assist_nodes or n.tag == "span" and (
                re.fullmatch(r"\(\d+\)", n.text()) or list(n.find("div")) and
                all(d in assist_nodes for d in n.find("div"))))]
        known = scorer is not None and all(assists) and len(assists) <= 2 and bool(team) and not unexpected
        event = {"type": "goal", "period": period, "time": time, "time_basis": "cumulative",
                 "score": [int(score[1]), int(score[2])], "strength": score[3], "team_code": team,
                 "scorer": scorer, "assists": assists, "attribution_complete": known,
                 "source_url": fixture["match_url"]}
        # shortcut: no official event IDs; score corrections can replace keys, reconcile complete snapshots.
        event["id"] = f'{fixture["fixture_id"]}:goal:{score[1]}-{score[2]}'
        event["id_kind"] = "derived_score_transition"
        event["revision"] = fingerprint(event)
        events.append(event)
    unique = {}
    for event in events:
        unique.setdefault(event["id"], {})[event["revision"]] = event
    result = []
    for revisions in unique.values():
        if len(revisions) > 1:
            errors.append("ambiguous repeated scoring transition")
            result.extend(dict(event, id=event["id"] + ":ambiguous:" + event["revision"]) for event in revisions.values())
        else:
            result.extend(revisions.values())
    return result, latest, errors


def match_lookup(config, selected, fixture_id, now, sources):
    output = {"status": "unavailable", "checked_at": now.astimezone(STOCKHOLM).isoformat(),
              "season": config["season"], "fixture_id": fixture_id, "match": None,
              "players": [], "errors": [], "sources": sources.coverage}
    candidates, verified = [], {}
    valid = config["valid_from"] <= now.astimezone(STOCKHOLM).date().isoformat() < config["valid_until"]
    for key in selected:
        player = config["players"][key]
        report = {"player": key, "name": player["official_name"], "identity": "unknown", "errors": [],
                  "lineup": {"status": "unconfirmed", "source_url": None},
                  "direct_events": [], "event_evidence": "unknown", "goals": None, "assists": None}
        output["players"].append(report)
        verified[key] = set()
        if not valid or not player["teams"]:
            report["errors"].append("expired/not yet valid mapping or no verified teams")
            continue
        for mapping in player["teams"]:
            try:
                games = schedule(sources.get(mapping["schedule"]), mapping["schedule"], config["season"])
                candidates.extend(g for g in games if g["fixture_id"] == fixture_id
                                  and mapping["team"] in (g["home"], g["away"]))
            except (ValueError, OSError) as exc:
                report["errors"].append(str(exc))
            try:
                raw = sources.get(mapping["roster"])
                roster(raw, mapping, player, config["season"])
                # Names alone cannot distinguish same-name teammates in match events.
                doc = Document(raw)
                names = [cells(r)[1].text() for t in tables(doc) for r in t.find("tr")
                         if len(cells(r)) >= 3 and cells(r)[1].text() == player["official_name"]]
                if len(names) != 1:
                    raise ValueError("ambiguous roster name for event attribution")
                verified[key].add(mapping["team"])
            except (ValueError, OSError) as exc:
                report["errors"].append(str(exc))
    if not candidates:
        output["errors"].append("fixture not found in successfully checked configured-team schedules; failed coverage is unknown")
        return output
    fixture = candidates[0]
    if any({k: v for k, v in g.items() if k != "source_url"} !=
           {k: v for k, v in fixture.items() if k != "source_url"} for g in candidates):
        output["errors"].append("conflicting official fixture " + fixture_id)
        return output
    match = dict(fixture, summary={"status": "unknown", "score": None, "period": None, "clock": None},
                 events=[], events_complete=False, attribution_complete=False,
                 latest_event={"period": None, "time": None}, errors=[])
    output["match"] = match
    doc, lineup_source, lineup_url, codes = None, None, None, {}
    team_events = set()
    try:
        if not fixture["match_url"]:
            raise ValueError("no official match link; game ID must not be inferred")
        doc = Document(sources.get(fixture["match_url"]))
        verify_game(doc, fixture)
    except (ValueError, OSError) as exc:
        match["errors"].append(str(exc))
        doc = None
    if doc:
        titles = [n.text() for n in doc.root.find("title")]
        if len(titles) == 1:
            pairing = re.fullmatch(r"(.+?)\s+-\s+(.+?)(?:\s+\([^)]*\))?", titles[0])
            if pairing and pairing[1] != pairing[2]:
                codes = dict(zip(pairing.groups(), (fixture["home"], fixture["away"])))
        try:
            match["summary"] = match_panel(doc)
            if match["summary"]["status"] == "unknown":
                match["errors"].append("unsupported or unpublished official panel status")
            if fixture["status"] in {"postponed", "cancelled"} and match["summary"]["status"] != fixture["status"]:
                match["errors"].append("schedule and panel statuses conflict")
        except ValueError as exc:
            match["errors"].append(str(exc))
        try:
            events, latest, errors = goal_events(doc, fixture)
            match.update(events=events, latest_event=latest)
            match["errors"].extend(errors)
            score = match["summary"]["score"]
            ordered = sorted(events, key=lambda e: sum(e["score"]))
            previous, consistent = [0, 0], True
            for event in ordered:
                transition = event["score"]
                delta = [transition[i] - previous[i] for i in (0, 1)]
                expected = fixture["home"] if delta == [1, 0] else fixture["away"] if delta == [0, 1] else None
                if expected and codes.get(event["team_code"]) == expected:
                    team_events.add(event["id"])
                else:
                    consistent = False
                previous = transition
            match["events_complete"] = not errors and score is not None and consistent and previous == score
            match["attribution_complete"] = match["events_complete"] and all(e["attribution_complete"] for e in events)
            if not match["events_complete"]:
                match["errors"].append("goal snapshot incomplete or inconsistent with panel score")
            elif not match["attribution_complete"]:
                match["errors"].append("goal attribution incomplete")
        except ValueError as exc:
            match["errors"].append(str(exc))
        try:
            links = {official_url(a.attrs["href"]) for a in doc.root.find("a")
                     if re.fullmatch(r"/Game/LineUps/[0-9]+", a.attrs.get("href", ""))}
            if len(links) != 1:
                raise ValueError("official lineup link missing or ambiguous")
            lineup_url = links.pop()
            if lineup_url.rsplit("/", 1)[1] != fixture["match_url"].rsplit("/", 1)[1]:
                raise ValueError("lineup link identifies a different game")
            lineup_source = sources.get(lineup_url)
        except (ValueError, OSError) as exc:
            match["errors"].append(str(exc))
    for report in output["players"]:
        configured = {m["team"] for m in config["players"][report["player"]]["teams"]}
        if not configured & {fixture["home"], fixture["away"]}:
            report["event_evidence"] = "not_applicable"
            report["lineup"]["reason"] = "fixture does not involve a configured team"
            continue
        teams = verified[report["player"]] & {fixture["home"], fixture["away"]}
        report["identity"] = "verified" if teams else "unknown"
        if not teams:
            report["errors"].append("player identity not verified for this fixture")
            continue
        if lineup_source:
            try:
                statuses = [lineup(lineup_source, fixture, team, report["name"]) for team in teams]
                status = "listed" if "listed" in statuses else "not_listed" if all(s == "not_listed" for s in statuses) else "unconfirmed"
                report["lineup"] = {"status": status, "source_url": lineup_url}
            except ValueError as exc:
                report["errors"].append(str(exc))
        if report["lineup"]["status"] == "unconfirmed":
            report["errors"].append("lineup unpublished/unavailable; not proof of ice time")
        for event in match["events"]:
            if event["id"] not in team_events or codes.get(event["team_code"]) not in teams:
                continue
            roles = (["goal"] if event["scorer"] == report["name"] else []) + (["assist"] if report["name"] in event["assists"] else [])
            report["direct_events"].extend({"event_id": event["id"], "revision": event["revision"], "role": role} for role in roles)
        complete = match["attribution_complete"] and all(e["team_code"] in codes for e in match["events"])
        report["event_evidence"] = "direct_event" if report["direct_events"] else "none_in_snapshot" if complete else "unknown"
        if complete:
            report["goals"] = sum(e["role"] == "goal" for e in report["direct_events"])
            report["assists"] = sum(e["role"] == "assist" for e in report["direct_events"])
        else:
            report["errors"].append("player goal/assist totals unknown; retained direct evidence is a lower bound")
    output["status"] = "partial" if match["errors"] or any(p["errors"] for p in output["players"]) else "ok"
    return output


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
    parser.add_argument("--match", metavar="FIXTURE_ID", help="official fixture number from schedule; implies JSON")
    args = parser.parse_args()
    try:
        config = json.loads(args.config.read_text())
        selected = list(dict.fromkeys(args.players or config["players"]))
        unknown = set(selected) - config["players"].keys()
        if unknown or not selected:
            raise ValueError("unknown/empty player selection: " + ", ".join(sorted(unknown)))
        if args.match is not None and not re.fullmatch(r"[0-9]+", args.match):
            raise ValueError("fixture ID must contain only digits")
        result = (match_lookup(config, selected, args.match, datetime.now(timezone.utc), Sources()) if args.match is not None
                  else lookup(config, selected, datetime.now(timezone.utc), Sources()))
    except (OSError, ValueError, KeyError, TypeError) as exc:
        result = {"status": "unavailable", "errors": [str(exc)]}
    if args.json or args.match is not None:
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
