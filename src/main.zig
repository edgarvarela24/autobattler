const rl = @import("raylib");
const game = @import("autobattler");
const std = @import("std");

const Unit = game.combat.Unit;
const Battle = game.combat.Battle;

pub fn main() !void {
    rl.initWindow(800, 450, "Autobattler");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var Warrior = Unit{
        .name = "Warrior",
        .health = 100,
        .attack = 10,
        .initiative = 5,
    };

    var Barbarian = Unit{
        .name = "Barbarian",
        .health = 120,
        .attack = 8,
        .initiative = 4,
    };

    const team_a: []const *Unit = &.{&Warrior};
    const team_b: []const *Unit = &.{&Barbarian};

    const allocator = std.heap.page_allocator;

    var battle = try Battle.init(allocator, team_a, team_b);
    defer battle.deinit(allocator);

    while (!rl.windowShouldClose()) {
        if (battle.state != .COMPLETED and rl.isKeyPressed(.space)) {
            try battle.advance();
        }
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        try drawUnit(Warrior, 80, 80, .blue);
        try drawUnit(Barbarian, 640, 80, .red);
    }
}

fn drawUnit(unit: Unit, x: i32, y: i32, color: rl.Color) !void {
    var scratch_buffer: [128]u8 = undefined;
    rl.drawRectangle(x, y, 80, 80, color);
    const name_text = try unit.getDisplayName(&scratch_buffer);
    rl.drawText(name_text, x, y - 30, 20, .white);
    const stats_text = try unit.getStatsDisplay(&scratch_buffer);
    rl.drawText(stats_text, x, y + 90, 20, .white);
}
