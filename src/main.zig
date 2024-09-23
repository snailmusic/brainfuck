const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    var argbuffer: [2048]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&argbuffer);
    var args = try std.process.argsWithAllocator(fba.allocator());
    defer args.deinit();
    _ = args.skip();
    const filename = args.next() orelse "main.bf";

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const stdin_file = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_file);
    const stdin = br.reader();

    const cwd = std.fs.cwd();
    const inFile = try cwd.openFile(filename, .{ .mode = .read_only });
    const inReader = inFile.reader();

    var buffer: [1024]u8 = undefined;
    @memset(buffer[0..], 0);
    _ = try inReader.readAll(buffer[0..]);
    try stdout.print("{s}\n", .{buffer});

    try bw.flush(); // don't forget to flush!

    // brainfuck stuff
    var tape: [30000]u8 = undefined;
    @memset(tape[0..], 0);
    var stack: [128]?usize = undefined;

    var tape_pointer: usize = 0;
    var stack_pointer: usize = 0;
    var code_pointer: usize = 0;
    tape_pointer = 0;
    stack_pointer = 0;

    while (code_pointer < buffer.len) {
        const op = buffer[code_pointer];

        switch (op) {
            '+' => {
                tape[tape_pointer] = tape[tape_pointer] +% 1;

                if (builtin.mode == std.builtin.OptimizeMode.Debug) std.debug.print("{d}: {d}\n", .{ tape_pointer, tape[tape_pointer] });
            },
            '-' => {
                tape[tape_pointer] = tape[tape_pointer] -% 1;

                if (builtin.mode == std.builtin.OptimizeMode.Debug) std.debug.print("{d}: {d}\n", .{ tape_pointer, tape[tape_pointer] });
            },
            '>' => {
                if (builtin.mode == std.builtin.OptimizeMode.Debug) std.debug.print("{d} -> ", .{tape_pointer});
                if (tape_pointer + 1 == tape.len) {
                    tape_pointer = 0;
                } else {
                    tape_pointer += 1;
                }

                if (builtin.mode == std.builtin.OptimizeMode.Debug) std.debug.print("{d}\n", .{tape_pointer});
            },
            '<' => {
                if (builtin.mode == std.builtin.OptimizeMode.Debug) std.debug.print("{d} -> ", .{tape_pointer});
                if (tape_pointer == 0) {
                    tape_pointer = tape.len - 1;
                } else {
                    tape_pointer -= 1;
                }

                if (builtin.mode == std.builtin.OptimizeMode.Debug) std.debug.print("{d}\n", .{tape_pointer});
            },
            '[' => {
                stack[stack_pointer] = code_pointer;
                stack_pointer += 1;
                if (stack_pointer >= stack.len) {
                    return error.StackOverflow;
                }
            },
            ']' => {
                if (tape[tape_pointer] == 0) {
                    if (stack_pointer != 0) {
                        stack_pointer -= 1;
                        stack[stack_pointer] = null;
                    }
                } else {
                    if (stack_pointer == 0) {
                        code_pointer = 0;
                    } else {
                        code_pointer = stack[stack_pointer - 1].?;
                    }
                }
            },
            '.' => {
                try stdout.print("{c}", .{tape[tape_pointer]});
            },
            ',' => {
                tape[tape_pointer] = try stdin.readByte();
            },
            else => {},
        }

        code_pointer += 1;
    }
    try bw.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
