"""Named routes only; permissions and child lifecycle remain Hermes core's job."""

from agent.delegation_provider import DelegationProvider, DelegationRouteError, ROUTE_KEYS


class Team(DelegationProvider):
    @property
    def name(self):
        return "silicon-valley-team"

    def task_parameters(self, config):
        members = self.settings(config).get("members", {})
        return {"teammate": {
            "type": "string",
            "enum": sorted(members),
            "description": "; ".join(
                f"{name}: {members[name]['description']}" for name in sorted(members)
            ),
        }}

    def description(self, config):
        return (
            "Silicon Valley team: Richard is the lead on the existing main route; "
            "Richard handles approved schedule changes. Set teammate to monica for "
            "documentation: writes docs, records decisions, checks docs against changes; "
            "or jared for routine review/summaries only. "
            "Jared cannot manage cron jobs and has no fallback escalation. "
            "These are working roles, not permission isolation. "
            "Omit teammate to preserve ordinary inherited delegation."
        )

    def route_task(self, task, config):
        if "teammate" not in task:
            return dict(config)
        members = self.settings(config).get("members", {})
        name = task["teammate"]
        if not isinstance(name, str) or name not in members:
            raise DelegationRouteError("Unknown teammate; use monica or jared, or omit teammate.")
        return {
            **{key: value for key, value in members[name].items() if key in ROUTE_KEYS},
            "label": name.title(),
        }


def register(ctx):
    ctx.register_delegation_provider(Team())
