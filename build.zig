const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;

const build_path = "build";
const build_path_c = "ref/build";
const default_cflags = "-pipe -Wall -O3 -fomit-frame-pointer -march=native";

const Target = struct {
    name: []const u8,
    libs: ?[]const u8,
    cflags: []const u8,
};

const targets = [_]Target{
    Target{
        .name = "k-nucleotide",
        .libs = "c",
        .cflags = default_cflags ++ " -std=c99 -fopenmp",
    },
    Target{
        .name = "binary-trees",
        .libs = "c",
        .cflags = default_cflags,
    },
    Target{
        .name = "fannkuch-redux",
        .libs = null,
        .cflags = default_cflags,
    },
    Target{
        .name = "fasta",
        .libs = null,
        .cflags = default_cflags ++ " -std=c99 -fopenmp -mfpmath=sse -msse3",
    },
    Target{
        .name = "mandelbrot",
        .libs = null,
        .cflags = default_cflags ++ " -fopenmp -mno-fma -fno-finite-math-only -mfpmath=sse",
    },
    Target{
        .name = "n-body",
        .libs = null,
        .cflags = default_cflags ++ " -mfpmath=sse -msse3",
    },
    Target{
        .name = "pidigits",
        .libs = "c gmp",
        .cflags = default_cflags,
    },
    Target{
        .name = "reverse-complement",
        .libs = "c",
        .cflags = default_cflags ++ " -funroll-loops -fopenmp",
    },
    Target{
        .name = "spectral-norm",
        .libs = null,
        .cflags = default_cflags ++ " -fopenmp -mfpmath=sse -msse3",
    },
    Target{
        .name = "regex-redux",
        .libs = "c pcre omp",
        .cflags = default_cflags ++ " -fopenmp",
    },
};

const CreateDirStep = struct {
    const Step = std.build.Step;

    step: Step,
    builder: *Builder,
    dir_path: []const u8,
    allow_existing: bool,

    pub fn init(builder: *Builder, dir_path: []const u8, allow_existing: bool) CreateDirStep {
        return CreateDirStep{
            .builder = builder,
            .step = Step.init(.custom, builder.fmt("CreateDir {s}", .{dir_path}), builder.allocator, make),
            .dir_path = dir_path,
            .allow_existing = allow_existing,
        };
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(CreateDirStep, "step", step);

        const full_path = self.builder.pathFromRoot(self.dir_path);
        std.fs.makeDirAbsolute(full_path) catch |err| {
            if (self.allow_existing and err == error.PathAlreadyExists) {
                return;
            }

            std.debug.warn("Unable to create {s}: {s}\n", .{ full_path, @errorName(err) });
            return err;
        };
    }
};

fn addCreateDirStep(self: *Builder, dir_path: []const u8, allow_existing: bool) *CreateDirStep {
    const create_dir_step = self.allocator.create(CreateDirStep) catch unreachable;
    create_dir_step.* = CreateDirStep.init(self, dir_path, allow_existing);
    return create_dir_step;
}

pub fn build(b: *Builder) !void {
    const create_build_dir = addCreateDirStep(b, build_path, true);
    const create_build_c_dir = addCreateDirStep(b, build_path_c, true);

    inline for (targets) |target| {
        // Zig Target
        {
            const exe = b.addExecutable(target.name, "src/" ++ target.name ++ ".zig");
            exe.setBuildMode(.ReleaseFast);
            exe.step.dependOn(&create_build_dir.step);
            exe.setOutputDir(build_path);

            if (target.libs) |libs| {
                var it = std.mem.split(u8, libs, " ");
                while (it.next()) |lib| {
                    exe.linkSystemLibrary(lib);
                }
            }

            b.default_step.dependOn(&exe.step);
        }

        // C Target
        {
            const exe = b.addExecutable(target.name, null);

            var cflags = std.ArrayList([]const u8).init(b.allocator);
            defer cflags.deinit();

            var cflag_it = std.mem.split(u8, target.cflags, " ");
            while (cflag_it.next()) |flag| {
                try cflags.append(flag);
            }

            exe.addCSourceFile("ref/" ++ target.name ++ ".c", cflags.items);
            exe.addIncludeDir("ref/include");
            exe.step.dependOn(&create_build_c_dir.step);
            exe.setOutputDir(build_path_c);

            if (target.libs) |libs| {
                var it = std.mem.split(u8, libs, " ");
                while (it.next()) |lib| {
                    exe.linkSystemLibrary(lib);
                }
            } else {
                // Building c files so we always link libc
                exe.linkSystemLibrary("c");
            }

            b.default_step.dependOn(&exe.step);
        }
    }

    const clean_build_path = b.addRemoveDirTree(build_path);
    const clean_build_path_c = b.addRemoveDirTree(build_path_c);

    const clean_step = b.step("clean", "Clean build directories");
    clean_step.dependOn(&clean_build_path.step);
    clean_step.dependOn(&clean_build_path_c.step);
}
