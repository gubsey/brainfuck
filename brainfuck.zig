const Tape = @import("./tape.zig").Tape(i32);

const std = @import("std");
const Allocater = std.mem.Allocator;


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
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = GPA.deinit();
    const gpa = GPA.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const file = args[1];
    const instructions = try lex(file, gpa);
    defer gpa.free(instructions);

    try run(instructions, gpa);
}

fn lex(file_name: []const u8, alloc: Allocater) ![]Ins {
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var reader = file.reader();

    var ar = std.ArrayList(Ins).init(alloc);

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
    defer stack.deinit();

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

fn run(instructions: []Ins, alloc: Allocater) !void {
    const tape = try Tape.init(alloc, 0);
    defer tape.deinit();

    const pairs = try bracket_pairs(instructions, alloc);
    defer alloc.free(pairs);

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
