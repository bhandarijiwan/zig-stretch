const std = @import("std");
const testing = std.testing;


test "flex_direction_row" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var node_1_style = Style.default();
    node_1_style.size.width = Dimension{ .Points = 10.0 };

    const node_1 = try stretch.new_node(node_1_style, &[_]Node{});

    var node_2_style = Style.default();
    node_2_style.size.width = Dimension{ .Points = 10.0 };

    const node_2 = try stretch.new_node(node_2_style, &[_]Node{});

    var node_3_style = Style.default();
    node_3_style.size.width = Dimension{ .Points = 10.0 };

    const node_3 = try stretch.new_node(node_3_style, &[_]Node{});

    var node_style = Style.default();
    node_style.size.width = Dimension{ .Points = 100.0 };
    node_style.size.height = Dimension{ .Points = 100.0 };

    const node = try stretch.new_node(node_style, &[_]Node{ node_1, node_2, node_3 });

    try stretch.compute_layout(node, UndefinedSize());
}
