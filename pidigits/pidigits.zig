// Resolve C translation compile error.

const std = @import("std");
const c = @cImport(@cInclude("gmp.h"));

const PiDigitsIterator = struct {
    const Self = this;

    i: usize,
    k: usize,
    n: usize,
    t1: c.mpz_t,
    t2: c.mpz_t,
    ac: c.mpz_t,
    dn: c.mpz_t,
    nm: c.mpz_t,

    pub fn init(n: usize) -> Self {
        var it: Self = undefined;
        it.i = 0;
        it.k = 0;
        it.n = n;
        c.mpz_init(&it.t1[0]);
        c.mpz_init(&it.t2[0]);
        c.mpz_init_set_ui(&it.ac[0], 0);
        c.mpz_init_set_ui(&it.dn[0], 1);
        c.mpz_init_set_ui(&it.nm[0], 1);

        return it;
    }

    pub fn deinit(self: &Self) {
        c.mpz_clear(&self.t1[0]);
        c.mpz_clear(&self.t2[0]);
        c.mpz_clear(&self.ac[0]);
        c.mpz_clear(&self.dn[0]);
        c.mpz_clear(&self.nm[0]);
    }

    pub fn next(self: &Self) -> ?usize {
        while (self.i < self.n) {
            self.nextTerm(self.k);
            self.k += 1;

            if (c.mpz_cmp(&self.nm[0], &self.ac[0]) > 0) {
                continue;
            }

            const d = self.extractDigit(3);
            if (d != self.extractDigit(4)) {
                continue;
            }

            self.i += 1;
            self.eliminateDigit(d);

            return usize(d);
        }

        return null;
    }

    fn nextTerm(self: &Self, k: usize) {
        const k2 = k * 2 + 1;

        c.mpz_addmul_ui(&self.ac[0], &self.nm[0], 2);
        c.mpz_mul_ui(&self.ac[0], &self.ac[0], k2);
        c.mpz_mul_ui(&self.dn[0], &self.dn[0], k2);
        c.mpz_mul_ui(&self.nm[0], &self.nm[0], k);
    }

    fn extractDigit(self: &Self, n: usize) -> usize {
        c.mpz_mul_ui(&self.t1[0], &self.nm[0], n);
        c.mpz_add(&self.t2[0], &self.t1[0], &self.ac[0]);
        c.mpz_tdiv_q(&self.t1[0], &self.t2[0], &self.dn[0]);

        return c.mpz_get_ui(&self.t1[0]);
    }

    fn eliminateDigit(self: &Self, d: usize) {
        c.mpz_submul_ui(&self.ac[0], &self.dn[0], d);
        c.mpz_mul_ui(&self.ac[0], &self.ac[0], 10);
        c.mpz_mul_ui(&self.nm[0], &self.nm[0], 10);
    }
};

const digits_n = 50;
const line_length = 10;

pub fn main() -> %void {
    var stdout_file = %return std.io.getStdOut();
    var stdout_out_stream = std.io.FileOutStream.init(&stdout_file);
    const stdout = &stdout_out_stream.stream;

    var pi = PiDigitsIterator.init(digits_n);
    defer pi.deinit();

    var i: usize = 1;
    while (pi.next()) |digit| {
        _ = stdout.print("{}", '0' + digit);
        if (i % line_length == 0) {
            _ = stdout.print("\t:{}\n", i);
        }
        i += 1;
    }
}
