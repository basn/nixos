"""Synthetic public-HTML shapes only: no private mappings or captured pages."""

from contextlib import redirect_stdout
from copy import deepcopy
from datetime import datetime, timezone
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import hockey


NOW = datetime(2032, 2, 3, 17, tzinfo=timezone.utc)
SCHEDULE = hockey.BASE + "/ScheduleAndResults/Schedule/123"
ROSTER = hockey.BASE + "/Teams/Info/TeamRoster/456"
EVENTS = hockey.BASE + "/Game/Events/987654"
LINEUP = hockey.BASE + "/Game/LineUps/987654"
CONFIG = {
    "season": "2031/2032", "valid_from": "2031-08-01", "valid_until": "2032-08-01",
    "players": {
        "Carl": {"official_name": "Example, Orion", "birth_date": "2013-04-05",
                 "teams": [{"team": "Fiction Foxes", "schedule": SCHEDULE, "roster": ROSTER}]},
        "Gustav": {"official_name": "Sample, Vega", "birth_date": "2013-06-07",
                   "teams": [{"team": "Fiction Foxes", "schedule": SCHEDULE, "roster": ROSTER}]},
    },
}


def page(body, title="FOX - OWL (1-0)"):
    return f"<html><head><title>{title}</title></head><body>{body}</body></html>"


def heading():
    return "<h2>Fiction Foxes - Imaginary Owls</h2><h3>2032-02-03 19:00</h3>"


def schedule(link=True, annotation="Final", score="1-0", date="2032-02-03 19:00"):
    score = f'<a href="javascript:openonlinewindow(\'/Game/Events/987654\',\'\')">{score}</a>' if link else score
    return page(f'''<select><option selected="selected">2031/2032</option></select>
        <table class="tblContent"><tr><th><h2>Schedule and Results</h2></th></tr>
        <tr><td>1</td><td><span class="lnkTooltip" title="42420001">{date}</span></td>
        <td>Fiction Foxes - Imaginary Owls<br/><i>{annotation}</i></td><td>{score}</td>
        <td></td><td></td><td>Invented Rink</td></tr></table>''')


def roster():
    return page('''<select><option selected="selected">2031/2032</option></select>
        <table class="tblContent"><tr><th>Fiction Foxes</th></tr>
        <tr><td>11</td><td>Example, Orion</td><td>2013-04-05</td></tr>
        <tr><td>22</td><td>Sample, Vega</td><td>2013-06-07</td></tr></table>''')


def goal(scorer="Example, Orion", assist="Sample, Vega", score="1-0", time="04:15", period="1st period", tooltip=True):
    assist_html = f'<div style="padding-left: 10px; font-weight:normal;">22. {assist}</div>' if assist else ""
    if tooltip and assist_html:
        assist_html = f'<span class="lnkTooltip">{assist_html}</span>'
    return f'''<tr><th class="tdSubTitle" colspan="5"><h3>{period}</h3></th></tr>
        <tr><td>{time}</td><td>{score} (EQ)</td><td>FOX</td><td>11. {scorer}
        <span title="Total goals scored in tournament">(99)</span>{assist_html}
        <td>Pos. Part.: 11, 22, 44<br/>Neg. Part.: 5, 6</td></td></tr>'''


def events(status="Final Score", score="1 - 0", rows=None, link=True):
    if rows is None:
        rows = goal()
    return page(heading() + f'''<table><tr><td class="tdInfoArea"><div>{score}</div>
        <div>(1-0, 0-0, 0-0)</div><div>{status}</div><div>Spectators: 123</div></td></tr></table>
        {f'<a href="/Game/LineUps/987654">Line Up</a>' if link else ''}
        <table class="tblContent"><tr><th><h2>Actions</h2></th><th><h2>Last update: irrelevant</h2></th></tr>
        {rows}</table>''')


def lineup(published=True):
    return page(heading() + '''<h2>Line Up</h2><table class="tblContent">
        <tr><th><h3>Fiction Foxes (Blue)</h3></th></tr>''' + ('''
        <tr><td><div class="lineUpPlayer">11. Example, Orion</div>
        <div class="lineUpPlayer">22. Sample, Vega (LW)</div></td></tr>''' if published else "") + "</table>")


class Sources:
    def __init__(self, pages=None):
        self.pages = {SCHEDULE: schedule(), ROSTER: roster(), EVENTS: events(), LINEUP: lineup()}
        self.pages.update(pages or {})
        self.coverage, self.calls = [], []

    def get(self, url):
        hockey.official_url(url)
        self.calls.append(url)
        content = self.pages.get(url)
        self.coverage.append({"url": url, "status": "ok" if content else "unavailable"})
        if content is None:
            raise OSError("synthetic source unavailable")
        return content


class MatchTests(unittest.TestCase):
    def lookup(self, pages=None, selected=None, config=None, fixture="42420001"):
        return hockey.match_lookup(config or CONFIG, selected or list(CONFIG["players"]), fixture, NOW, Sources(pages))

    def test_final_both_players_exact_schedule_link_and_evidence(self):
        sources = Sources()
        result = hockey.match_lookup(CONFIG, list(CONFIG["players"]), "42420001", NOW, sources)
        self.assertEqual(result["status"], "ok")
        self.assertEqual(result["match"]["summary"]["status"], "final")
        self.assertIn(EVENTS, sources.calls)
        self.assertFalse(any(url.endswith("/42420001") for url in sources.calls))
        carl, gustav = result["players"]
        self.assertEqual((carl["goals"], carl["assists"]), (1, 0))
        self.assertEqual((gustav["goals"], gustav["assists"]), (0, 1))
        self.assertEqual(carl["lineup"]["status"], "listed")
        self.assertEqual(gustav["event_evidence"], "direct_event")
        event = result["match"]["events"][0]
        self.assertEqual(event["assists"], ["Sample, Vega"])
        self.assertEqual(event["scorer"], "Example, Orion")
        self.assertEqual(event["time_basis"], "cumulative")

    def test_future_unpublished_and_missing_link(self):
        result = self.lookup({SCHEDULE: schedule(link=False, annotation="", score="")})
        self.assertEqual(result["status"], "partial")
        self.assertIsNotNone(result["match"])
        self.assertFalse(result["match"]["events_complete"])
        self.assertIsNone(result["players"][0]["goals"])
        result = self.lookup({EVENTS: events("Not started", "0 - 0", ""), LINEUP: lineup(False)})
        self.assertEqual(result["match"]["summary"]["status"], "scheduled")
        self.assertEqual(result["players"][0]["lineup"]["status"], "unconfirmed")
        result = self.lookup({EVENTS: events("Waiting for 1st period", "-", "")})
        self.assertEqual(result["match"]["summary"]["status"], "scheduled")
        self.assertIsNone(result["match"]["summary"]["score"])
        self.assertFalse(result["match"]["events_complete"])

    def test_live_score_and_round_final_never_mean_final(self):
        result = self.lookup({EVENTS: events("2nd period 25:30", rows=goal(time="24:15", period="2nd period"))})
        self.assertEqual(result["match"]["summary"]["status"], "live")
        self.assertEqual(result["match"]["summary"]["clock"], "25:30")
        self.assertEqual(result["match"]["latest_event"], {"period": "2nd period", "time": "24:15"})
        result = self.lookup({EVENTS: events("Unrecognized state")})
        self.assertEqual(result["match"]["summary"]["status"], "unknown")
        self.assertEqual(result["status"], "partial")
        self.assertTrue(result["match"]["events_complete"])

    def test_overtime(self):
        result = self.lookup({EVENTS: events(rows=goal(time="70:21", period="1st overtime"))})
        self.assertEqual(result["match"]["events"][0]["period"], "1st overtime")
        self.assertEqual(result["match"]["events"][0]["time"], "70:21")

    def test_individual_failures_retain_other_evidence(self):
        for url in (ROSTER, LINEUP, EVENTS):
            with self.subTest(url=url):
                result = self.lookup({url: None})
                self.assertEqual(result["status"], "partial")
                self.assertIsNotNone(result["match"])
                if url != EVENTS:
                    self.assertEqual(result["match"]["summary"]["score"], [1, 0])
                    self.assertTrue(result["match"]["events"])
                if url == ROSTER:
                    self.assertEqual(result["players"][0]["identity"], "unknown")
                    self.assertEqual(result["players"][0]["direct_events"], [])
                if url == LINEUP:
                    self.assertTrue(result["players"][0]["direct_events"])
        result = self.lookup({EVENTS: events().replace('<h2>Actions</h2>', '<h2>Unknown</h2>')})
        self.assertEqual(result["match"]["summary"]["score"], [1, 0])
        self.assertEqual(result["players"][0]["lineup"]["status"], "listed")
        self.assertFalse(result["match"]["events_complete"])

    def test_missing_lineup_link_and_postponement(self):
        result = self.lookup({EVENTS: events(link=False)})
        self.assertTrue(result["players"][0]["direct_events"])
        self.assertEqual(result["status"], "partial")
        result = self.lookup({SCHEDULE: schedule(link=False, annotation="Postponed", score="")})
        self.assertEqual(result["match"]["status"], "postponed")
        self.assertEqual(result["match"]["summary"]["status"], "unknown")
        result = self.lookup({EVENTS: events("Postponed", "", "")})
        self.assertEqual(result["match"]["summary"]["status"], "postponed")

    def test_fixture_identity_and_not_found(self):
        for source in (EVENTS, LINEUP):
            result = self.lookup({source: (events() if source == EVENTS else lineup()).replace("2032-02-03", "2032-02-04")})
            self.assertEqual(result["status"], "partial")
            if source == EVENTS:
                self.assertEqual(result["match"]["events"], [])
            else:
                self.assertEqual(result["players"][0]["lineup"]["status"], "unconfirmed")
        self.assertEqual(self.lookup(fixture="999")["status"], "unavailable")
        result = self.lookup({ROSTER: roster().replace("2013-04-05", "2013-04-06")})
        self.assertEqual(result["players"][0]["identity"], "unknown")
        self.assertEqual(result["players"][1]["identity"], "verified")
        result = self.lookup({EVENTS: events().replace("/LineUps/987654", "/LineUps/1")})
        self.assertEqual(result["players"][0]["lineup"]["status"], "unconfirmed")

    def test_stable_ids_revisions_corrections_and_removals(self):
        first = self.lookup()
        again = self.lookup(selected=["Carl"])
        self.assertEqual(first["match"]["events"], again["match"]["events"])
        corrected = self.lookup({EVENTS: events(rows=goal("Sample, Vega", "Example, Orion"))})
        old, new = first["match"]["events"][0], corrected["match"]["events"][0]
        self.assertEqual(old["id"], new["id"])
        self.assertNotEqual(old["revision"], new["revision"])
        self.assertEqual(corrected["players"][0]["assists"], 1)
        corrected = self.lookup({EVENTS: events(rows=goal(assist=None))})
        self.assertEqual(corrected["players"][1]["assists"], 0)
        self.assertNotEqual(old["revision"], corrected["match"]["events"][0]["revision"])
        removed = self.lookup({EVENTS: events(score="0 - 0", rows="")})
        self.assertTrue(removed["match"]["events_complete"])
        self.assertEqual(removed["match"]["events"], [])
        self.assertEqual(removed["players"][0]["goals"], 0)
        incomplete = self.lookup({EVENTS: events(rows="")})
        self.assertFalse(incomplete["match"]["events_complete"])
        self.assertIsNone(incomplete["players"][0]["goals"])

    def test_row_order_duplicates_and_changed_score_keys(self):
        rows = [goal(), goal(score="2-0", time="08:00")]
        first = self.lookup({EVENTS: events(score="2 - 0", rows="".join(rows))})
        reordered = self.lookup({EVENTS: events(score="2 - 0", rows="".join(reversed(rows)))})
        self.assertEqual({e["id"]: e["revision"] for e in first["match"]["events"]},
                         {e["id"]: e["revision"] for e in reordered["match"]["events"]})
        self.assertTrue(first["match"]["events_complete"])
        repeated = self.lookup({EVENTS: events(rows=goal() * 2)})
        self.assertEqual(len(repeated["match"]["events"]), 1)
        self.assertTrue(repeated["match"]["events_complete"])
        rows = [goal(), goal(scorer="Sample, Vega")]
        first = self.lookup({EVENTS: events(rows="".join(rows))})
        reordered = self.lookup({EVENTS: events(rows="".join(reversed(rows)))})
        self.assertEqual({e["id"] for e in first["match"]["events"]}, {e["id"] for e in reordered["match"]["events"]})
        self.assertFalse(first["match"]["events_complete"])
        changed = self.lookup({EVENTS: events(score="0 - 1", rows=goal(score="0-1"))})
        self.assertNotEqual(self.lookup()["match"]["events"][0]["id"], changed["match"]["events"][0]["id"])
        self.assertFalse(changed["match"]["events_complete"])  # Home code contradicts away score increment.
        self.assertEqual(changed["players"][0]["direct_events"], [])

    def test_partial_schedule_coverage_conflicts_and_expiry(self):
        config = deepcopy(CONFIG)
        other = hockey.BASE + "/ScheduleAndResults/Schedule/124"
        config["players"]["Carl"]["teams"][0]["schedule"] = other
        result = self.lookup({other: None}, config=config)
        self.assertEqual(result["status"], "partial")
        self.assertTrue(result["match"]["events_complete"])
        result = self.lookup({other: schedule(date="2032-02-04 19:00")}, config=config)
        self.assertEqual(result["status"], "unavailable")
        self.assertIsNone(result["match"])
        config["valid_until"] = "2032-02-03"
        self.assertEqual(self.lookup(config=config)["status"], "unavailable")
        result = self.lookup({SCHEDULE: schedule(annotation="Postponed")})
        self.assertEqual(result["status"], "partial")

    def test_same_name_roster_and_unmapped_team_are_unknown(self):
        duplicate = roster().replace("</table>", '<tr><td>33</td><td>Example, Orion</td><td>2013-09-10</td></tr></table>')
        result = self.lookup({ROSTER: duplicate})
        self.assertEqual(result["players"][0]["identity"], "unknown")
        result = self.lookup({EVENTS: events().replace("FOX - OWL (1-0)", "unrecognized title")})
        self.assertIsNone(result["players"][0]["goals"])
        self.assertEqual(result["players"][0]["direct_events"], [])

    def test_ambiguous_attribution_is_not_zero(self):
        result = self.lookup({EVENTS: events(rows=goal(scorer="(unpublished)"))})
        self.assertTrue(result["match"]["events_complete"])
        self.assertFalse(result["match"]["attribution_complete"])
        self.assertIsNone(result["players"][0]["goals"])
        self.assertEqual(result["players"][0]["event_evidence"], "unknown")
        self.assertTrue(result["players"][1]["direct_events"])
        result = self.lookup({EVENTS: events(rows=goal().replace("padding-left: 10px", "unknown-style: 10px"))})
        self.assertFalse(result["match"]["attribution_complete"])
        self.assertIsNone(result["players"][1]["assists"])

    def test_allowlist_and_limits_unchanged(self):
        for url in ("https://example.org/Game/Events/1", "http://stats.swehockey.se/Game/Events/1",
                    EVENTS + "?token=no", EVENTS + "#fragment", hockey.BASE + "/Game/Reports/1"):
            with self.assertRaises(ValueError):
                hockey.official_url(url)
        self.assertEqual(hockey.LIMIT, 2 * 1024 * 1024)

    def test_existing_lookup_and_cli_json_exit(self):
        result = hockey.lookup(CONFIG, ["Carl"], NOW, Sources({SCHEDULE: schedule(annotation="", score="")}))
        self.assertEqual(result["players"][0]["today"][0]["fixture_id"], "42420001")
        self.assertEqual(result["players"][0]["next"]["fixture_id"], "42420001")
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "synthetic.json"
            path.write_text(json.dumps(CONFIG))
            for pages, code in (({}, 0), ({EVENTS: None}, 1)):
                out = io.StringIO()
                with patch("sys.argv", ["hockey", "--config", str(path), "--match", "42420001", "Carl"]), \
                        patch.object(hockey, "Sources", return_value=Sources(pages)), \
                        patch.object(hockey, "datetime") as clock, redirect_stdout(out):
                    clock.now.return_value = NOW
                    clock.strptime = datetime.strptime
                    self.assertEqual(hockey.main(), code)
                self.assertEqual(json.loads(out.getvalue())["players"][0]["player"], "Carl")


if __name__ == "__main__":
    unittest.main()
