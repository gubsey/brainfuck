const std = @import("std");
const Allocater = std.mem.Allocator;

const List = LinkedList(i32);

const Ins = enum {
    Right,
    Left,
    Increment,
    Decrement,
    Output,
    Input,
    Open,
    Close,
};

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    const file = args[1];
    const instructions = try lex(file);

    try run(instructions);
}

fn lex(file_name: []const u8) ![]Ins {
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var reader = file.reader();

    var ar = std.ArrayList(Ins).init(std.heap.page_allocator);

    while (true) {
        const b = reader.readByte() catch break;
        const ins: Ins = switch (b) {
            '>' => Ins.Right,
            '<' => Ins.Left,
            '+' => Ins.Increment,
            '-' => Ins.Decrement,
            '.' => Ins.Output,
            ',' => Ins.Input,
            '[' => Ins.Open,
            ']' => Ins.Close,
            else => {
                continue;
            },
        };

        try ar.append(ins);
    }

    return ar.toOwnedSlice();
}

const Pair = struct {
    open: usize,
    close: usize,
};

fn bracket_pairs(instructions: []Ins, alloc: Allocater) ![]Pair {
    var r = std.ArrayList(Pair).init(alloc);
    var stack = std.ArrayList(Pair).init(alloc);

    for (instructions, 0..) |ins, i| {
        switch (ins) {
            Ins.Open => try stack.append(Pair{ .open = i, .close = undefined }),
            Ins.Close => {
                var pair = stack.pop();
                pair.close = i;
                try r.append(pair);
            },
            else => continue,
        }
    }

    return try r.toOwnedSlice();
}

fn run(instructions: []Ins) !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = GPA.allocator();
    const tape = try List.init(gpa, 0);

    const pairs = try bracket_pairs(instructions, gpa);

    var ndx: usize = 0;
    while (ndx < instructions.len) : (ndx += 1) {
        const ins = instructions[ndx];
        switch (ins) {
            Ins.Right => try tape.move_right(),
            Ins.Left => try tape.move_left(),
            Ins.Increment => tape.cur.data += 1,
            Ins.Decrement => tape.cur.data -= 1,
            Ins.Output => std.debug.print("{c}", .{@as(u8, @intCast(tape.cur.data))}),
            Ins.Input => tape.cur.data = try std.io.getStdIn().reader().readByte(),
            Ins.Open => if (tape.cur.data == 0) {
                for (pairs) |pair| {
                    if (pair.open == ndx) {
                        ndx = pair.close;
                        break;
                    }
                }
            },
            Ins.Close => {
                for (pairs) |pair| {
                    if (pair.close == ndx) {
                        ndx = pair.open - 1;
                        break;
                    }
                }
            },
        }
    }
}

fn LinkedList(comptime T: type) type {
    return struct {
        pub const Node = struct {
            data: T,
            left: ?*Node = null,
            right: ?*Node = null,
        };

        fn init(alloc: Allocater, default: T) !*LinkedList(T) {
            const list = try alloc.create(LinkedList(T));
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

        fn move_right(self: *@This()) !void {
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

        fn move_left(self: *@This()) !void {
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
