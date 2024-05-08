const std = @import("std");
const Allocater = std.mem.Allocator;

/// A doubly linked list designed for [brainfuck](https://www.muppetlabs.com/~breadbox/bf/)
pub fn Tape(comptime T: type) type {
    return struct {
        pub const Node = struct {
            data: T,
            left: ?*Node = null,
            right: ?*Node = null,
        };

        pub fn deinit(self: *@This()) void {
            var cur = self.first;
            while (cur.right) |x| {
                self.alloc.destroy(cur);
                cur = x;
                self.len -= 1;
            }

            self.alloc.destroy(cur);
            self.alloc.destroy(self);
        }

        pub fn init(alloc: Allocater, default: T) !*Tape(T) {
            const list = try alloc.create(Tape(T));
            const node = try alloc.create(Node);

            node.* = .{ .data = default };

            list.* = .{
                .cur = node,
                .first = node,
                .last = node,
                .len = 1,
                .default = default,
                .alloc = alloc,
            };

            return list;
        }

        pub fn move_right(self: *@This()) !void {
            if (self.cur.right) |x| {
                self.cur = x;
            } else {
                const node = try self.alloc.create(Node);

                node.* = .{ .data = self.default, .left = self.cur };

                self.cur.right = node;
                self.cur = node;
                self.last = node;
                self.len += 1;
            }
        }

        pub fn move_left(self: *@This()) !void {
            if (self.cur.left) |x| {
                self.cur = x;
            } else {
                const node = try self.alloc.create(Node);

                node.* = .{ .data = self.default, .right = self.cur };

                self.cur.left = node;
                self.cur = node;
                self.first = node;
                self.len += 1;
            }
        }

        cur: *Node,
        first: *Node,
        last: *Node,
        len: usize,

        alloc: Allocater,
        default: T,
    };
}
