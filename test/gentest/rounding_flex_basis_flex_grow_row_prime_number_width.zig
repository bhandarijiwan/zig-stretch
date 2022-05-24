// This was generated by codegen script.

const std = @import("std");
const testing = std.testing;

test "rounding_flex_basis_flex_grow_row_prime_number_width" {
    const S = @import("stretch");
    var stretch = try S.Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var node_1_style = S.Style.default();
    node_1_style.flex_grow = 1.0;

    const node_1 = try stretch.new_node(node_1_style, &[_]S.Node{});

    var node_2_style = S.Style.default();
    node_2_style.flex_grow = 1.0;

    const node_2 = try stretch.new_node(node_2_style, &[_]S.Node{});

    var node_3_style = S.Style.default();
    node_3_style.flex_grow = 1.0;

    const node_3 = try stretch.new_node(node_3_style, &[_]S.Node{});

    var node_4_style = S.Style.default();
    node_4_style.flex_grow = 1.0;

    const node_4 = try stretch.new_node(node_4_style, &[_]S.Node{});

    var node_5_style = S.Style.default();
    node_5_style.flex_grow = 1.0;

    const node_5 = try stretch.new_node(node_5_style, &[_]S.Node{});

    var node_style = S.Style.default();
    node_style.size.width = S.Dimension{ .Points = 113.0 };
    node_style.size.height = S.Dimension{ .Points = 100.0 };

    const node = try stretch.new_node(node_style, &[_]S.Node{ node_1, node_2, node_3, node_4, node_5 });

    try stretch.compute_layout(node, S.UndefinedSize());

    const node_layout = try stretch.layout(node);
    try std.testing.expect(node_layout.size.width == 113.0);
    try std.testing.expect(node_layout.size.height == 100.0);
    try std.testing.expect(node_layout.location.x == 0.0);
    try std.testing.expect(node_layout.location.y == 0.0);

    const node_1_layout = try stretch.layout(node_1);
    try std.testing.expect(node_1_layout.size.width == 23.0);
    try std.testing.expect(node_1_layout.size.height == 100.0);
    try std.testing.expect(node_1_layout.location.x == 0.0);
    try std.testing.expect(node_1_layout.location.y == 0.0);

    const node_2_layout = try stretch.layout(node_2);
    try std.testing.expect(node_2_layout.size.width == 23.0);
    try std.testing.expect(node_2_layout.size.height == 100.0);
    try std.testing.expect(node_2_layout.location.x == 23.0);
    try std.testing.expect(node_2_layout.location.y == 0.0);

    const node_3_layout = try stretch.layout(node_3);
    try std.testing.expect(node_3_layout.size.width == 23.0);
    try std.testing.expect(node_3_layout.size.height == 100.0);
    try std.testing.expect(node_3_layout.location.x == 45.0);
    try std.testing.expect(node_3_layout.location.y == 0.0);

    const node_4_layout = try stretch.layout(node_4);
    try std.testing.expect(node_4_layout.size.width == 23.0);
    try std.testing.expect(node_4_layout.size.height == 100.0);
    try std.testing.expect(node_4_layout.location.x == 68.0);
    try std.testing.expect(node_4_layout.location.y == 0.0);

    const node_5_layout = try stretch.layout(node_5);
    try std.testing.expect(node_5_layout.size.width == 23.0);
    try std.testing.expect(node_5_layout.size.height == 100.0);
    try std.testing.expect(node_5_layout.location.x == 90.0);
    try std.testing.expect(node_5_layout.location.y == 0.0);
}