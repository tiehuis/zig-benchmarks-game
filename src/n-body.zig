// NOTE: This is slow, test the following to see what helps:
//
// - use hardware sqrt instruction instead of library
// - increase unroll level a lot to see if this helps
// - determine why our accuracy is slightly off here

const std = @import("std");
const builtin = @import("builtin");
const math = std.math;

const solar_mass = 4.0 * math.pi * math.pi;
const year = 365.24;

const Planet = struct {
    x: f64,
    y: f64,
    z: f64,
    vx: f64,
    vy: f64,
    vz: f64,
    mass: f64,
};

fn advance(bodies: []Planet, dt: f64, steps: usize) void {
    var i: usize = 0;
    while (i < steps) : (i += 1) {
        for (bodies) |*bi, j| {
            for (bodies[j + 1 ..]) |*bj| {
                const dx = bi.x - bj.x;
                const dy = bi.y - bj.y;
                const dz = bi.z - bj.z;

                const dsq = dx * dx + dy * dy + dz * dz;
                const dst = math.sqrt(dsq);
                const mag = dt / (dsq * dst);
                const mi = bi.mass;

                bi.vx -= dx * bj.mass * mag;
                bi.vy -= dy * bj.mass * mag;
                bi.vz -= dz * bj.mass * mag;

                bj.vx += dx * mi * mag;
                bj.vy += dy * mi * mag;
                bj.vz += dz * mi * mag;
            }
        }

        for (bodies) |*bi| {
            bi.x += dt * bi.vx;
            bi.y += dt * bi.vy;
            bi.z += dt * bi.vz;
        }
    }
}

fn energy(bodies: []const Planet) f64 {
    var e: f64 = 0.0;

    for (bodies) |bi, i| {
        e += 0.5 * (bi.vx * bi.vx + bi.vy * bi.vy + bi.vz * bi.vz) * bi.mass;

        for (bodies[i + 1 ..]) |bj| {
            const dx = bi.x - bj.x;
            const dy = bi.y - bj.y;
            const dz = bi.z - bj.z;
            const dist = math.sqrt(dx * dx + dy * dy + dz * dz);
            e -= bi.mass * bj.mass / dist;
        }
    }

    return e;
}

fn offset_momentum(bodies: []Planet) void {
    var px: f64 = 0.0;
    var py: f64 = 0.0;
    var pz: f64 = 0.0;

    for (bodies) |b| {
        px += b.vx * b.mass;
        py += b.vy * b.mass;
        pz += b.vz * b.mass;
    }

    var sun = &bodies[0];
    sun.vx = -px / solar_mass;
    sun.vy = -py / solar_mass;
    sun.vz = -pz / solar_mass;
}

const solar_bodies = []const Planet{
    // Sun
    Planet{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
        .vx = 0.0,
        .vy = 0.0,
        .vz = 0.0,
        .mass = solar_mass,
    },
    // Jupiter
    Planet{
        .x = 4.84143144246472090e+00,
        .y = -1.16032004402742839e+00,
        .z = -1.03622044471123109e-01,
        .vx = 1.66007664274403694e-03 * year,
        .vy = 7.69901118419740425e-03 * year,
        .vz = -6.90460016972063023e-05 * year,
        .mass = 9.54791938424326609e-04 * solar_mass,
    },
    // Saturn
    Planet{
        .x = 8.34336671824457987e+00,
        .y = 4.12479856412430479e+00,
        .z = -4.03523417114321381e-01,
        .vx = -2.76742510726862411e-03 * year,
        .vy = 4.99852801234917238e-03 * year,
        .vz = 2.30417297573763929e-05 * year,
        .mass = 2.85885980666130812e-04 * solar_mass,
    },
    // Uranus
    Planet{
        .x = 1.28943695621391310e+01,
        .y = -1.51111514016986312e+01,
        .z = -2.23307578892655734e-01,
        .vx = 2.96460137564761618e-03 * year,
        .vy = 2.37847173959480950e-03 * year,
        .vz = -2.96589568540237556e-05 * year,
        .mass = 4.36624404335156298e-05 * solar_mass,
    },
    // Neptune
    Planet{
        .x = 1.53796971148509165e+01,
        .y = -2.59193146099879641e+01,
        .z = 1.79258772950371181e-01,
        .vx = 2.68067772490389322e-03 * year,
        .vy = 1.62824170038242295e-03 * year,
        .vz = -9.51592254519715870e-05 * year,
        .mass = 5.15138902046611451e-05 * solar_mass,
    },
};

var buffer: [32]u8 = undefined;
var fixed_allocator = std.heap.FixedBufferAllocator.init(buffer[0..]);
var allocator = &fixed_allocator.allocator;

pub fn main() !void {
    var stdout_file = try std.io.getStdOut();
    var stdout_out_stream = stdout_file.outStream();
    const stdout = &stdout_out_stream.stream;

    var args = std.os.args();
    _ = args.skip();
    const n = try std.fmt.parseUnsigned(u64, try args.next(allocator).?, 10);

    var bodies = solar_bodies;

    offset_momentum(bodies[0..]);
    try stdout.print("{.9}\n", energy(bodies[0..]));

    advance(bodies[0..], 0.01, n);
    try stdout.print("{.9}\n", energy(bodies[0..]));
}
