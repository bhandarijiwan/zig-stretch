// This was generated by codegen script.

const std = @import("std");
const testing = std.testing;

test "flex_basis_and_main_dimen_set_when_flexing" {
    const S = @import("stretch");
    var stretch = try S.Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var node_1_style = S.Style.default();
    node_1_style.flex_grow = 1.0;
    node_1_style.flex_basis = S.Dimension{ .Points = 10.0 };
    node_1_style.size.width = S.Dimension{ .Points = 50.0 };
    node_1_style.size.height = S.Dimension{ .Points = 50.0 };

    const node_1 = try stretch.new_node(node_1_style, &[_]S.Node{});

    var node_2_style = S.Style.default();
    node_2_style.flex_grow = 1.0;
    node_2_style.flex_basis = S.Dimension{ .Points = 10.0 };
    node_2_style.size.width = S.Dimension{ .Points = 0.0 };
    node_2_style.size.height = S.Dimension{ .Points = 50.0 };

    const node_2 = try stretch.new_node(node_2_style, &[_]S.Node{});

    var node_style = S.Style.default();
    node_style.size.width = S.Dimension{ .Points = 100.0 };

    const node = try stretch.new_node(node_style, &[_]S.Node{ node_1, node_2 });

    try stretch.compute_layout(node, S.UndefinedSize());

    const node_layout = try stretch.layout(node);
    try std.testing.expect(node_layout.size.width == 100.0);
    try std.testing.expect(node_layout.size.height == 50.0);
    try std.testing.expect(node_layout.location.x == 0.0);
    try std.testing.expect(node_layout.location.y == 0.0);

    const node_1_layout = try stretch.layout(node_1);
    try std.testing.expect(node_1_layout.size.width == 50.0);
    try std.testing.expect(node_1_layout.size.height == 50.0);
    try std.testing.expect(node_1_layout.location.x == 0.0);
    try std.testing.expect(node_1_layout.location.y == 0.0);

    const node_2_layout = try stretch.layout(node_2);
    try std.testing.expect(node_2_layout.size.width == 50.0);
    try std.testing.expect(node_2_layout.size.height == 50.0);
    try std.testing.expect(node_2_layout.location.x == 50.0);
    try std.testing.expect(node_2_layout.location.y == 0.0);
}
