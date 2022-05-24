// This was generated by codegen script.

const std = @import("std");
const testing = std.testing;

test "absolute_layout_child_order" {
    const S = @import("stretch");
    var stretch = try S.Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var node_1_style = S.Style.default();
    node_1_style.size.width = S.Dimension{ .Points = 60.0 };
    node_1_style.size.height = S.Dimension{ .Points = 40.0 };

    const node_1 = try stretch.new_node(node_1_style, &[_]S.Node{});

    var node_2_style = S.Style.default();
    node_2_style.position_type = S.PositionType.Absolute;
    node_2_style.size.width = S.Dimension{ .Points = 60.0 };
    node_2_style.size.height = S.Dimension{ .Points = 40.0 };

    const node_2 = try stretch.new_node(node_2_style, &[_]S.Node{});

    var node_3_style = S.Style.default();
    node_3_style.size.width = S.Dimension{ .Points = 60.0 };
    node_3_style.size.height = S.Dimension{ .Points = 40.0 };

    const node_3 = try stretch.new_node(node_3_style, &[_]S.Node{});

    var node_style = S.Style.default();
    node_style.align_items = S.AlignItems.Center;
    node_style.justify_content = S.JustifyContent.Center;
    node_style.size.width = S.Dimension{ .Points = 110.0 };
    node_style.size.height = S.Dimension{ .Points = 100.0 };

    const node = try stretch.new_node(node_style, &[_]S.Node{ node_1, node_2, node_3 });

    try stretch.compute_layout(node, S.UndefinedSize());

    const node_layout = try stretch.layout(node);
    try std.testing.expect(node_layout.size.width == 110.0);
    try std.testing.expect(node_layout.size.height == 100.0);
    try std.testing.expect(node_layout.location.x == 0.0);
    try std.testing.expect(node_layout.location.y == 0.0);

    const node_1_layout = try stretch.layout(node_1);
    try std.testing.expect(node_1_layout.size.width == 55.0);
    try std.testing.expect(node_1_layout.size.height == 40.0);
    try std.testing.expect(node_1_layout.location.x == 0.0);
    try std.testing.expect(node_1_layout.location.y == 30.0);

    const node_2_layout = try stretch.layout(node_2);
    try std.testing.expect(node_2_layout.size.width == 60.0);
    try std.testing.expect(node_2_layout.size.height == 40.0);
    try std.testing.expect(node_2_layout.location.x == 25.0);
    try std.testing.expect(node_2_layout.location.y == 30.0);

    const node_3_layout = try stretch.layout(node_3);
    try std.testing.expect(node_3_layout.size.width == 55.0);
    try std.testing.expect(node_3_layout.size.height == 40.0);
    try std.testing.expect(node_3_layout.location.x == 55.0);
    try std.testing.expect(node_3_layout.location.y == 30.0);
}
