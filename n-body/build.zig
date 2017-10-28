const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("n-body", "n-body.zig");
    exe.setBuildMode(mode);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
