const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("spectral-norm", "spectral-norm.zig");
    exe.setBuildMode(mode);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
