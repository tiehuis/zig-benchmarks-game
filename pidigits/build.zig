const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("pidigits", "pidigits.zig");
    exe.setBuildMode(mode);

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("gmp");

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
