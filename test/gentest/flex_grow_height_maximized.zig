// This was generated by codegen script.

const std = @import("std");
const testing = std.testing;

test "flex_grow_height_maximized" {
    const S = @import("stretch");
    var stretch = try S.Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var node_1_1_style = S.Style.default();
    node_1_1_style.flex_grow = 1.0;
    node_1_1_style.flex_basis = S.Dimension{ .Points = 200.0 };

    const node_1_1 = try stretch.new_node(node_1_1_style, &[_]S.Node{});

    var node_1_2_style = S.Style.default();
    node_1_2_style.size.height = S.Dimension{ .Points = 100.0 };

    const node_1_2 = try stretch.new_node(node_1_2_style, &[_]S.Node{});

    var node_1_style = S.Style.default();
    node_1_style.flex_direction = S.FlexDirection.Column;
    node_1_style.flex_grow = 1.0;
    node_1_style.min_size.height = S.Dimension{ .Points = 100.0 };
    node_1_style.max_size.height = S.Dimension{ .Points = 500.0 };

    const node_1 = try stretch.new_node(node_1_style, &[_]S.Node{ node_1_1, node_1_2 });

    var node_style = S.Style.default();
    node_style.flex_direction = S.FlexDirection.Column;
    node_style.size.width = S.Dimension{ .Points = 100.0 };
    node_style.size.height = S.Dimension{ .Points = 500.0 };

    const node = try stretch.new_node(node_style, &[_]S.Node{node_1});

    try stretch.compute_layout(node, S.UndefinedSize());

    const node_layout = try stretch.layout(node);
    try std.testing.expect(node_layout.size.width == 100.0);
    try std.testing.expect(node_layout.size.height == 500.0);
    try std.testing.expect(node_layout.location.x == 0.0);
    try std.testing.expect(node_layout.location.y == 0.0);

    const node_1_layout = try stretch.layout(node_1);
    try std.testing.expect(node_1_layout.size.width == 100.0);
    try std.testing.expect(node_1_layout.size.height == 500.0);
    try std.testing.expect(node_1_layout.location.x == 0.0);
    try std.testing.expect(node_1_layout.location.y == 0.0);

    const node_1_1_layout = try stretch.layout(node_1_1);
    try std.testing.expect(node_1_1_layout.size.width == 100.0);
    try std.testing.expect(node_1_1_layout.size.height == 400.0);
    try std.testing.expect(node_1_1_layout.location.x == 0.0);
    try std.testing.expect(node_1_1_layout.location.y == 0.0);

    const node_1_2_layout = try stretch.layout(node_1_2);
    try std.testing.expect(node_1_2_layout.size.width == 100.0);
    try std.testing.expect(node_1_2_layout.size.height == 100.0);
    try std.testing.expect(node_1_2_layout.location.x == 0.0);
    try std.testing.expect(node_1_2_layout.location.y == 400.0);
}
