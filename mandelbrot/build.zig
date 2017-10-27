const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("mandelbrot", "mandelbrot.zig");
    exe.setBuildMode(mode);
    exe.setOutputPath("./mandelbrot");

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
