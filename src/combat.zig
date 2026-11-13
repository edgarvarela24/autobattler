const std = @import("std");

const Unit = struct {
    name: []const u8,
    health: i32,
    attack: i32,
    initiative: i32,
    fn isAlive(self: *const Unit) bool {
        return self.health > 0;
    }
};

const Participant = struct {
    unit: *Unit,
    team: Team,
};

const Team = enum {
    Team1,
    Team2,
};

fn attackUnit(unit1: *const Unit, unit2: *Unit) !void {
    if (!unit1.isAlive()) {
        return error.UnitIsDead;
    }
    unit2.health -= unit1.attack;
}

test "attackUnit causes second unit to take damage" {
    var warrior = Unit{
        .name = "warrior",
        .health = 10,
        .attack = 5,
        .initiative = 5,
    };

    var enemy = Unit{
        .name = "enemy",
        .health = 8,
        .attack = 3,
        .initiative = 3,
    };

    try attackUnit(&warrior, &enemy);

    try std.testing.expectEqual(10, warrior.health);
    try std.testing.expectEqual(3, enemy.health);
    try std.testing.expectEqual(true, enemy.isAlive());
}

test "attackUnit can kill a unit when health is exactly zero" {
    var warrior = Unit{
        .name = "warrior",
        .health = 10,
        .attack = 5,
        .initiative = 5,
    };

    var enemy = Unit{
        .name = "enemy",
        .health = 5,
        .attack = 3,
        .initiative = 3,
    };

    try attackUnit(&warrior, &enemy);

    try std.testing.expectEqual(0, enemy.health);
    try std.testing.expectEqual(false, enemy.isAlive());
}

test "attackUnit can kill a unit when health is below zero" {
    var warrior = Unit{
        .name = "warrior",
        .health = 10,
        .attack = 5,
        .initiative = 5,
    };

    var enemy = Unit{
        .name = "enemy",
        .health = 4,
        .attack = 3,
        .initiative = 3,
    };

    try attackUnit(&warrior, &enemy);

    try std.testing.expectEqual(-1, enemy.health);
    try std.testing.expectEqual(false, enemy.isAlive());
}

test "cannot attack a unit if attacker has zero health" {
    var dead_guy = Unit{
        .name = "dead guy",
        .health = 0,
        .attack = 5,
        .initiative = 5,
    };
    var enemy = Unit{
        .name = "enemy",
        .health = 10,
        .attack = 3,
        .initiative = 3,
    };

    try std.testing.expectError(error.UnitIsDead, attackUnit(&dead_guy, &enemy));
    try std.testing.expectEqual(10, enemy.health);
}

test "cannot attack a unit if attacker has negative health" {
    var dead_guy = Unit{
        .name = "dead guy",
        .health = -1,
        .attack = 5,
        .initiative = 5,
    };
    var enemy = Unit{
        .name = "enemy",
        .health = 10,
        .attack = 3,
        .initiative = 3,
    };

    try std.testing.expectError(error.UnitIsDead, attackUnit(&dead_guy, &enemy));
    try std.testing.expectEqual(10, enemy.health);
}

fn byInitiative(_: void, unit1: Participant, unit2: Participant) bool {
    return unit1.unit.initiative > unit2.unit.initiative;
}

fn autoBattle(allocator: std.mem.Allocator, team1: []const *Unit, team2: []const *Unit) !void {
    const turn_order = try allocator.alloc(Participant, team1.len + team2.len);
    defer allocator.free(turn_order);

    for (team1, 0..) |unit, i| {
        turn_order[i] = .{
            .unit = unit,
            .team = .Team1,
        };
    }

    for (team2, 0..) |unit, i| {
        turn_order[team1.len + i] = .{
            .unit = unit,
            .team = .Team2,
        };
    }

    std.mem.sort(Participant, turn_order, {}, byInitiative);

    var prng = std.Random.DefaultPrng.init(42);
    const rand = prng.random();

    while (teamHasLivingUnit(team1) and teamHasLivingUnit(team2)) {
        for (turn_order) |participant| {
            if (!participant.unit.isAlive()) {
                continue;
            }

            switch (participant.team) {
                .Team1 => {
                    const index = rand.uintLessThan(usize, team2.len);
                    const target = team2[index];
                    try attackUnit(participant.unit, target);
                },
                .Team2 => {
                    const index = rand.uintLessThan(usize, team1.len);
                    const target = team1[index];
                    try attackUnit(participant.unit, target);
                },
            }

            if (!teamHasLivingUnit(team1) or !teamHasLivingUnit(team2)) {
                break;
            }
        }
    }
}

test "initiative determines who attacks first" {
    var unit1 = Unit{
        .name = "unit1",
        .health = 10,
        .attack = 10,
        .initiative = 5,
    };
    var unit2 = Unit{
        .name = "unit2",
        .health = 10,
        .attack = 10,
        .initiative = 10,
    };

    const team1: []const *Unit = &.{&unit1};
    const team2: []const *Unit = &.{&unit2};

    const allocator = std.testing.allocator;

    try autoBattle(allocator, team1, team2);

    try std.testing.expectEqual(false, unit1.isAlive());
    try std.testing.expectEqual(10, unit2.health);
}

fn teamHasLivingUnit(team: []const *Unit) bool {
    for (team) |unit| {
        if (unit.isAlive()) {
            return true;
        }
    }
    return false;
}

test "dead participants are skipped" {
    var unit1 = Unit{
        .name = "unit1",
        .health = 0,
        .attack = 3,
        .initiative = 30,
    };
    var unit2 = Unit{
        .name = "unit2",
        .health = 10,
        .attack = 10,
        .initiative = 20,
    };
    var unit3 = Unit{
        .name = "unit3",
        .health = 10,
        .attack = 10,
        .initiative = 10,
    };

    const team1: []const *Unit = &.{ &unit1, &unit2 };
    const team2: []const *Unit = &.{&unit3};

    const allocator = std.testing.allocator;
    try autoBattle(allocator, team1, team2);

    try std.testing.expectEqual(false, unit1.isAlive());
    try std.testing.expectEqual(0, unit1.health);
    try std.testing.expectEqual(true, unit2.isAlive());
    try std.testing.expectEqual(10, unit2.health);
    try std.testing.expectEqual(false, unit3.isAlive());
    try std.testing.expectEqual(0, unit3.health);
}

test "combat continues across multiple rounds" {
    var unit1 = Unit{
        .name = "unit1",
        .health = 10,
        .attack = 3,
        .initiative = 30,
    };
    var unit2 = Unit{
        .name = "unit2",
        .health = 10,
        .attack = 3,
        .initiative = 20,
    };

    const team1: []const *Unit = &.{&unit1};
    const team2: []const *Unit = &.{&unit2};

    const allocator = std.testing.allocator;
    try autoBattle(allocator, team1, team2);

    try std.testing.expectEqual(true, unit1.isAlive());
    try std.testing.expectEqual(1, unit1.health);
    try std.testing.expectEqual(false, unit2.isAlive());
}

test "combat ends immediately when a team is defeated" {
    var unit1 = Unit{
        .name = "unit1",
        .health = 10,
        .attack = 10,
        .initiative = 30,
    };
    var unit2 = Unit{
        .name = "unit2",
        .health = 10,
        .attack = 10,
        .initiative = 20,
    };
    var unit3 = Unit{
        .name = "unit3",
        .health = 10,
        .attack = 10,
        .initiative = 10,
    };

    const team1: []const *Unit = &.{ &unit1, &unit2 };
    const team2: []const *Unit = &.{&unit3};

    const allocator = std.testing.allocator;
    try autoBattle(allocator, team1, team2);

    try std.testing.expectEqual(true, unit1.isAlive());
    try std.testing.expectEqual(true, unit2.isAlive());
    try std.testing.expectEqual(false, unit3.isAlive());
    try std.testing.expectEqual(0, unit3.health);
}
