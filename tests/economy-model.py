"""Deterministic pacing estimates from current Luau tuning; no game/data writes.

Run: python tests/economy-model.py
Trip times are hypotheses, not captured player telemetry. The output separates
display fill time and expected accrual from the real delivery/collection inputs.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parent.parent


def read(path):
    return (ROOT / path).read_text(encoding="utf-8-sig")


def number(source, name):
    match = re.search(rf"\b{re.escape(name)}\s*=\s*([0-9.]+)", source)
    if not match:
        raise ValueError(f"Missing numeric tuning: {name}")
    return float(match[1])


def egg_definitions():
    source = read("scripts/collection/Config.lua")
    starts = list(re.finditer(r"^\t\t(\w+Egg)\s*=\s*\{", source, re.MULTILINE))
    result = {}
    for index, match in enumerate(starts):
        end = starts[index + 1].start() if index + 1 < len(starts) else source.index("\n\tInteractionDistance")
        block = source[match.start():end]
        bands = [tuple(map(float, values)) for values in re.findall(
            r'Name\s*=\s*"\w+",\s*Min\s*=\s*(\d+),\s*Max\s*=\s*(\d+),\s*Weight\s*=\s*(\d+)', block)]
        mean = (sum((low + high) / 2 * weight for low, high, weight in bands) / sum(b[2] for b in bands)
                if bands else number(block, "Income"))
        result[match[1]] = {"expected_per_second": mean, "respawn_seconds": number(block, "RespawnSeconds"),
                            "shared": "Shared = true" in block}
    if set(result) != {"CommonEgg", "UncommonEgg", "RareEgg", "StormEgg"}:
        raise ValueError("Review the model for the changed egg catalogue")
    return result


def time_to_accrue(goal, income, capacity, first_delivery, interval):
    """Expected income ramps with sequential deliveries; stop adding at capacity.

    This is gross accrued currency with zero spending/theft/failure. It assumes
    collection when needed, so it is a lower bound on actually buying an item.
    """
    elapsed = wallet = rate = 0.0
    next_delivery = first_delivery
    for _ in range(capacity):
        gap = next_delivery - elapsed
        if rate and wallet + gap * rate >= goal:
            return elapsed + (goal - wallet) / rate
        wallet += gap * rate
        elapsed = next_delivery
        rate += income
        next_delivery += interval
    return elapsed + max(0, goal - wallet) / rate


def main():
    eggs = egg_definitions()
    boosts = [int(value) for value in re.findall(r"\[\d+\]\s*=\s*\{[^}]*Price\s*=\s*(\d+)", read("scripts/boost/Config.lua"))][1:]
    if len(boosts) != 5:
        raise ValueError("Review the model for the changed boost table")
    costs = {"first_boost": boosts[0], "bat": int(number(read("scripts/combat/Config.lua"), "BatPrice")),
             "shield": int(number(read("scripts/combat/Config.lua"), "ShieldPrice")),
             "rebirth": int(number(read("scripts/progression/RebirthConfig.lua"), "Cost")),
             "all_five_boosts": sum(boosts)}
    rows = []
    for template, capacity in [("CommonEgg", 6), ("UncommonEgg", 6), ("RareEgg", 6), ("StormEgg", 12)]:
        definition = eggs[template]
        for trip in [30, 45, 60]:
            hold = trip / 2
            # Shared Common is independently claimable by each player. Exclusive
            # sources are held until delivery/loss, then start their respawn delay.
            solo_interval = max(trip, hold + definition["respawn_seconds"])
            if definition["shared"]:
                solo_interval = max(trip, definition["respawn_seconds"])
            row = {"egg": template, "assumed_round_trip_seconds": trip, "capacity": capacity,
                   "expected_full_display_per_second": definition["expected_per_second"] * capacity,
                   "solo_fill_seconds": round(trip + (capacity - 1) * solo_interval, 2)}
            row["solo_gross_goal_seconds"] = {name: round(time_to_accrue(cost, definition["expected_per_second"],
                capacity, trip, solo_interval), 2) for name, cost in costs.items()}
            if not definition["shared"]:
                # Optimistic perfectly fair six-person rotation. There is currently
                # no actual reservation queue, so repeated winners can starve others.
                fair_interval = max(trip, 6 * (hold + definition["respawn_seconds"]))
                first_average = trip + 2.5 * (hold + definition["respawn_seconds"])
                row["fair_six_player_fill_seconds"] = round(first_average + (capacity - 1) * fair_interval, 2)
                row["fair_six_player_gross_rebirth_seconds"] = round(time_to_accrue(costs["rebirth"],
                    definition["expected_per_second"], capacity, first_average, fair_interval), 2)
            rows.append(row)
    output = {"assumptions": {"trip_times_are_measured": False, "failures_theft_spending": False,
        "pickup_to_deposit_fraction_of_trip": 0.5, "six_player_distribution": "hypothetical fair rotation; not enforced",
        "goals": "independent gross accrued currency, not cumulative purchases or actual bank visits"},
        "eggs": eggs, "costs": costs, "forecasts": rows}
    assert eggs["RareEgg"]["expected_per_second"] == 412.5
    assert eggs["StormEgg"]["expected_per_second"] == 1562.5
    assert costs["all_five_boosts"] == 1305500
    target = ROOT / "tmp/economy-model-results.json"
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
