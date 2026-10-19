const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Vec(comptime T: type) type {
    return struct {
        used: usize = 0,
        array_list: []T = undefined,

        pub fn init(alc: Allocator) !Vec(T) {
            return Vec(T) {
                .array_list = try alc.alloc(T, 1),
            };
        }

        pub fn deinit(self: *Vec(T), alc: Allocator) void {
            alc.free(self.array_list);
        }

        pub fn push(self: *Vec(T), alc: Allocator, item: T) !void {
            if (self.used == self.array_list.len) {
                self.array_list = try alc.realloc(self.array_list, self.array_list.len * 2);
            }
            self.array_list[self.used] = item;
            self.used += 1;
            return;
        }

        pub fn get(self: *Vec(T), index: usize) !T {
            if (index >= self.used) {
                return error.IndexOutOfBounds;
            }
            return self.array_list[index];
        }

        pub fn len(self: *Vec(T)) usize {
            return self.array_list.len;
        }
    };
}

pub fn Stack(comptime T: type) type {
    return struct {
        used: usize = 0,
        stack: []T = undefined,

        pub fn init(alc: Allocator) !Stack(T) {
            return Stack(T) {
                .stack = try alc.alloc(T, 1),
            };
        }

        pub fn deinit(self: *Stack(T), alc: Allocator) void {
            alc.free(self.stack);
        }

        pub fn push(self: *Stack(T), alc: Allocator, item: T) !void {
            if (self.used == self.stack.len) {
                self.stack = try alc.realloc(self.stack, self.stack.len * 2);
            }
            self.stack[self.used] = item;
            self.used += 1;
            return;
        }

        pub fn pop(self: *Stack(T)) !T {
            if (self.used == 0) {
                return error.EmptyStack;
            }
            self.used -= 1;
            return self.stack[self.used];
        }
    };
}

pub fn Queue(comptime T: type) type {
    return struct {
        head: usize = 0,
        tail: usize = 0,
        ring: []T = undefined,

        pub fn init(alc: Allocator) !Queue(T) {
            return Queue(T) {
                .ring = try alc.alloc(T, 2),
            };
        }

        pub fn deinit(self: *Queue(T), alc: Allocator) void {
            alc.free(self.ring);
        }

        pub fn print(self: *Queue(T)) void {
            for (0..self.ring.len) |i| {
                std.debug.print("{d} ", .{self.ring[i]});
            }
            std.debug.print("\n", .{});
        }

        pub fn push(self: *Queue(T), alc: Allocator, item: T) !void {
            self.ring[self.tail] = item;
            self.tail = (self.tail + 1) % self.ring.len;
            if (self.tail == self.head) {
                const old_len = self.ring.len;
                self.ring = try alc.realloc(self.ring, self.ring.len * 2);
                @memcpy(self.ring[self.head+old_len..self.ring.len], self.ring[self.head..old_len]);
                self.head = self.head + old_len;
            }
            return;
        }

        pub fn pop(self: *Queue(T)) !T {
            if (self.head == self.tail) {
                return error.EmptyQueue;
            }
            const x = self.ring[self.head];
            self.head = (self.head + 1) % self.ring.len;
            return x;
        }

        pub fn empty(self: *Queue(T)) bool {
            return self.head == self.tail;
        }
    };
}


const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

test "testing vec usage" {
    const alc = std.testing.allocator;

    var s = try Vec(u8).init(alc);
    defer s.deinit(alc);

    // data
    try s.push(alc, 8);
    try s.push(alc, 7);
    try s.push(alc, 4);

    try expectEqual(@as(u8, 4), try s.get(2));
    try expectEqual(@as(u8, 7), try s.get(1));

    try s.push(alc, 5);

    try expectEqual(@as(u8, 5), try s.get(3));
    try expectEqual(@as(u8, 8), try s.get(0));
    try expectError(error.IndexOutOfBounds, s.get(5));
}

test "testing stack usage" {
    const alc = std.testing.allocator;

    var s = try Stack(u8).init(alc);
    defer s.deinit(alc);

    // data
    try s.push(alc, 8);
    try s.push(alc, 7);
    try s.push(alc, 4);

    try expectEqual(@as(u8, 4), try s.pop());
    try expectEqual(@as(u8, 7), try s.pop());

    try s.push(alc, 5);

    try expectEqual(@as(u8, 5), try s.pop());
    try expectEqual(@as(u8, 8), try s.pop());
    try expectError(error.EmptyStack, s.pop());
}

test "testing queue usage" {
    const alc = std.testing.allocator;

    var q = try Queue(u8).init(alc);
    defer q.deinit(alc);

    // data
    try q.push(alc, 8);
    try q.push(alc, 7);
    try q.push(alc, 4);

    try expectEqual(@as(u8, 8), try q.pop());
    try expectEqual(@as(u8, 7), try q.pop());

    try q.push(alc, 5);

    try expectEqual(@as(u8, 4), try q.pop());
    try expectEqual(@as(u8, 5), try q.pop());
    try expectError(error.EmptyQueue, q.pop());
}

