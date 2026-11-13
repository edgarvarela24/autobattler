const std = @import("std");

const Unit = struct {
    name: []const u8,
    health: i32,
    attack: i32,
    fn isAlive(self: *const Unit) bool {
        return self.health > 0;
    }
};

fn attackUnit(unit1: *Unit, unit2: *Unit) !void {
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
    };

    var enemy = Unit{
        .name = "enemy",
        .health = 8,
        .attack = 3,
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
    };

    var enemy = Unit{
        .name = "enemy",
        .health = 5,
        .attack = 3,
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
    };

    var enemy = Unit{
        .name = "enemy",
        .health = 4,
        .attack = 3,
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
    };
    var enemy = Unit{
        .name = "enemy",
        .health = 10,
        .attack = 3,
    };

    try std.testing.expectError(error.UnitIsDead, attackUnit(&dead_guy, &enemy));
    try std.testing.expectEqual(10, enemy.health);
}

test "cannot attack a unit if attacker has negative health" {
    var dead_guy = Unit{
        .name = "dead guy",
        .health = -1,
        .attack = 5,
    };
    var enemy = Unit{
        .name = "enemy",
        .health = 10,
        .attack = 3,
    };

    try std.testing.expectError(error.UnitIsDead, attackUnit(&dead_guy, &enemy));
    try std.testing.expectEqual(10, enemy.health);
}
