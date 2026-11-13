const rl = @import("raylib");

pub fn main() !void {
    rl.initWindow(800, 450, "Autobattler");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var color_flag = true;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        if (color_flag) {
            rl.clearBackground(.black);
        } else {
            rl.clearBackground(.yellow);
        }
        color_flag = !color_flag;
        rl.drawText("SEIZURE TIME!!!", 190, 200, 20, .white);
    }
}
