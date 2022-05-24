// This was generated by codegen script.

const std = @import("std");
const testing = std.testing;

test "margin_auto_left_fix_right_child_bigger_than_parent" {
    const S = @import("stretch");
    var stretch = try S.Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var node_1_style = S.Style.default();
    node_1_style.size.width = S.Dimension{ .Points = 72.0 };
    node_1_style.size.height = S.Dimension{ .Points = 72.0 };
    node_1_style.margin.start = S.Dimension.Auto;
    node_1_style.margin.end = S.Dimension{ .Points = 10.0 };

    const node_1 = try stretch.new_node(node_1_style, &[_]S.Node{});

    var node_style = S.Style.default();
    node_style.justify_content = S.JustifyContent.Center;
    node_style.size.width = S.Dimension{ .Points = 52.0 };
    node_style.size.height = S.Dimension{ .Points = 52.0 };

    const node = try stretch.new_node(node_style, &[_]S.Node{node_1});

    try stretch.compute_layout(node, S.UndefinedSize());

    const node_layout = try stretch.layout(node);
    try std.testing.expect(node_layout.size.width == 52.0);
    try std.testing.expect(node_layout.size.height == 52.0);
    try std.testing.expect(node_layout.location.x == 0.0);
    try std.testing.expect(node_layout.location.y == 0.0);

    const node_1_layout = try stretch.layout(node_1);
    try std.testing.expect(node_1_layout.size.width == 42.0);
    try std.testing.expect(node_1_layout.size.height == 72.0);
    try std.testing.expect(node_1_layout.location.x == 0.0);
    try std.testing.expect(node_1_layout.location.y == 0.0);
}
