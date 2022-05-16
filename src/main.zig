const std = @import("std");
const testing = std.testing;

//#region Container
const Vec = std.ArrayList;
const ChildrenVec = std.ArrayList;
const ParentsVec = std.ArrayList;
const Allocator = std.mem.Allocator;
//#endregion Container

//#region geometry
pub fn Rect(comptime T: type) type {
    return struct {
        const Self = @This();
        start: T,
        end: T,
        top: T,
        bottom: T,

        pub fn default() Self {
            if (T == Dimension) {
                return Self{
                    .start = Dimension.default(),
                    .end = Dimension.default(),
                    .top = Dimension.default(),
                    .bottom = Dimension.default(),
                };
            }
            @compileError("type parameter can only be 'Dimension' when constructing a default rect. ");
        }

        pub fn map(self: Self, comptime R: type, rect_mapper: *RectMapper(T, R)) Rect(R) {
            return Rect(R){
                .start = rect_mapper.map(self.start),
                .end = rect_mapper.map(self.end),
                .top = rect_mapper.map(self.top),
                .bottom = rect_mapper.map(self.bottom),
            };
        }

        pub fn horizontal(self: Self) T {
            if (T == Number) {
                return self.start.add(self.end);
            } else {
                return self.start + self.end;
            }
        }

        pub fn vertical(self: Self) T {
            if (T == Number) {
                return self.top.add(self.bottom);
            } else {
                return self.top + self.bottom;
            }
        }

        pub fn main(self: Self, direction: FlexDirection) T {
            if (direction.is_row()) {
                return self.horizontal();
            } else {
                return self.vertical();
            }
        }

        pub fn cross(self: Self, direction: FlexDirection) T {
            if (direction.is_row()) {
                return self.vertical();
            } else {
                return self.horizontal();
            }
        }

        pub fn main_start(self: Self, direction: FlexDirection) T {
            if (direction.is_row()) {
                return self.start;
            } else {
                return self.top;
            }
        }

        pub fn main_end(self: Self, direction: FlexDirection) T {
            if (direction.is_row()) {
                return self.end;
            } else {
                return self.bottom;
            }
        }

        pub fn cross_start(self: Self, direction: FlexDirection) T {
            if (direction.is_row()) {
                return self.top;
            } else {
                return self.start;
            }
        }

        pub fn cross_end(self: Self, direction: FlexDirection) T {
            if (direction.is_row()) {
                return self.bottom;
            } else {
                return self.end;
            }
        }
    };
}

test "Rect" {
    const r1 = Rect(Number){
        .start = Number.default(),
        .end = Number.default(),
        .top = Number.default(),
        .bottom = Number.default(),
    };
    std.debug.print("\nRect(Number) horizontal Direction = {any}, {any} \n", .{ r1.start, r1.horizontal() });
    const r2 = Rect(i32){
        .start = 0,
        .top = 0,
        .end = 10,
        .bottom = 10,
    };
    std.debug.print("\n Rect(i32) Vertical Direction = {any} \n", .{r2.vertical()});
    std.debug.print("\n Rect(i32) Main Axis = {any} \n", .{r2.main(FlexDirection.Row)});
    std.debug.print("\n Rect(i32) Cross Axis = {any} \n", .{r2.cross(FlexDirection.Row)});
}

test "Rect default" {
    const r1 = Rect(Dimension).default();
    std.debug.print("\n default rect {}\n", .{r1});
    try std.testing.expect(r1.start == Dimension.@"Undefined");
    try std.testing.expect(r1.end == Dimension.@"Undefined");
    try std.testing.expect(r1.top == Dimension.@"Undefined");
    try std.testing.expect(r1.bottom == Dimension.@"Undefined");
}

pub fn Size(comptime T: type) type {
    return struct {
        const Self = @This();

        width: T,
        height: T,

        pub fn default() Size(T) {
            if (T == Dimension) {
                return Self{ .width = Dimension.Auto, .height = Dimension.Auto };
            }
            @compileError("type parameter can only be 'Dimension' when constructing a default size. ");
        }

        pub fn map(self: Self, comptime R: type, f: fn (T) R) Size(R) {
            return Size(R){
                .width = f(self.width),
                .height = f(self.height),
            };
        }

        pub fn set_main(self: Self, direction: FlexDirection, value: T) void {
            if (direction.is_row()) {
                self.width = value;
            } else {
                self.height = value;
            }
        }

        pub fn set_cross(self: Self, direction: FlexDirection, value: T) void {
            if (direction.is_row()) {
                self.height = value;
            } else {
                self.width = value;
            }
        }

        pub fn main(self: Self, direction: FlexDirection) T {
            if (direction.is_row()) {
                return self.width;
            } else {
                return self.height;
            }
        }

        pub fn cross(self: Self, direction: FlexDirection) T {
            if (direction.is_row()) {
                return self.height;
            } else {
                return self.width;
            }
        }

        pub fn resolve(self: Size(Dimension), parent: Size(Number)) Size(Number) {
            return Size(Number){ .width = self.width.resolve(parent.width), .height = self.height.resolve(parent.height) };
        }
    };
}

pub fn sizeAreEqual(left: Size(Number), right: Size(Number)) bool {
    const width_equal = switch (left.width) {
        .Defined => |lhs| switch (right.width) {
            .Defined => |rhs| lhs == rhs,
            else => false,
        },
        else => right.width.is_undefined(),
    };
    const height_equal = switch (left.height) {
        .Defined => |lhs| switch (right.height) {
            .Defined => |rhs| lhs == rhs,
            else => false,
        },
        else => right.height.is_undefined(),
    };
    return width_equal and height_equal;
}

test "default size" {
    std.debug.print("\n zero size {any}\n", .{Size(Dimension).default()});
    try std.testing.expect(Size(Dimension).default().width == Dimension.Auto);
    try std.testing.expect(Size(Dimension).default().height == Dimension.Auto);
}

test "resolve size" {
    const parentSize = Size(Number){ .width = Number{ .Defined = 100 }, .height = Number{ .Defined = 100 } };

    const childSize1 = Size(Dimension){ .width = Dimension{ .Percent = 0.2 }, .height = Dimension{ .Percent = 0.3 } };

    std.debug.print("\n Resolved Size = {any} \n", .{childSize1.resolve(parentSize)});

    const childSize2 = Size(Dimension){ .width = Dimension{ .Points = 20.0 }, .height = Dimension{ .Points = 30.0 } };
    std.debug.print("\n Resolved Size = {any} \n", .{childSize2.resolve(parentSize)});
}

pub fn UndefinedSize() Size(Number) {
    return Size(Number){ .width = Number.@"Undefined", .height = Number.@"Undefined" };
}

pub fn ZeroSize() Size(f32) {
    return Size(f32){ .width = 0.0, .height = 0.0 };
}

fn mapper(x: f32) i32 {
    return @floatToInt(i32, x) + 10;
}

fn mapperA(x: f32) f64 {
    return x + 10.0;
}

test "size" {
    const s1 = UndefinedSize();
    std.debug.print("\n s1 = {any} \n", .{s1});
    const s2 = ZeroSize();
    std.debug.print("\n s2 map = {any} \n", .{s2.map(i32, mapper)});
    std.debug.print("\n s3 map = {any} \n", .{ZeroSize().map(f64, mapperA)});
}

pub fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

pub fn ZeroPoint() Point(f32) {
    return Point(f32){ .x = 0.0, .y = 0.0 };
}

test "Point" {
    const p = ZeroPoint();
    std.debug.print("\npoint {any}\n", .{p});
}

fn RectMapper(comptime T: type, comptime R: type) type {
    return struct {
        const Self = @This();
        parent_size: Number,
        default_value: R,

        pub fn map(self: *Self, d: T) R {
            return d.resolve(self.parent_size).or_else_f32(self.default_value);
        }
    };
}

//#endregion geometry

//#region number

pub const Number = union(enum) {
    Defined: f32,
    @"Undefined",

    pub fn default() Number {
        return Number.@"Undefined";
    }

    pub fn from(n: f32) Number {
        return Number{ .Defined = n };
    }

    pub fn is_defined(self: Number) bool {
        return switch (self) {
            .Defined => true,
            .@"Undefined" => false,
        };
    }

    pub fn is_undefined(self: Number) bool {
        return switch (self) {
            .Defined => false,
            .@"Undefined" => true,
        };
    }

    pub fn div(self: Number, other: Number) Number {
        return switch (self) {
            .Defined => {
                return switch (other) {
                    .Defined => Number{ .Defined = self.Defined / other.Defined },
                    .@"Undefined" => Number.@"Undefined",
                };
            },
            .@"Undefined" => Number.@"Undefined",
        };
    }

    pub fn mul(self: Number, other: Number) Number {
        return switch (self) {
            .Defined => switch (other) {
                .Defined => Number{ .Defined = self.Defined * other.Defined },
                else => self,
            },
            else => Number.@"Undefined",
        };
    }

    pub fn mul_f32(self: Number, other: f32) Number {
        return switch (self) {
            .Defined => {
                return Number{ .Defined = self.Defined * other };
            },
            else => Number.@"Undefined",
        };
    }

    pub fn sub(self: Number, other: Number) Number {
        return switch (self) {
            .Defined => switch (other) {
                .Defined => Number{ .Defined = self.Defined - other.Defined },
                else => self,
            },
            else => Number.@"Undefined",
        };
    }

    pub fn sub_f32(self: Number, other: f32) Number {
        return switch (self) {
            .Defined => |val| Number{ .Defined = val - other },
            else => Number.@"Undefined",
        };
    }

    pub fn add(self: Number, other: Number) Number {
        return switch (self) {
            .Defined => switch (other) {
                .Defined => Number{ .Defined = self.Defined + other.Defined },
                else => self,
            },
            else => Number.@"Undefined",
        };
    }

    pub fn maybe_min(self: Number, rhs: Number) Number {
        return switch (self) {
            .Defined => switch (rhs) {
                .Defined => Number{ .Defined = std.math.min(self.Defined, rhs.Defined) },
                else => self,
            },
            else => Number.@"Undefined",
        };
    }

    pub fn maybe_max(self: Number, rhs: Number) Number {
        return switch (self) {
            .Defined => switch (rhs) {
                .Defined => Number{ .Defined = std.math.max(self.Defined, rhs.Defined) },
                else => self,
            },
            else => Number.@"Undefined",
        };
    }

    pub fn maybe_max_f32(self: Number, rhs: f32) Number {
        return switch (self) {
            .Defined => Number{ .Defined = std.math.max(self.Defined, rhs) },
            else => Number.@"Undefined",
        };
    }

    pub fn maybe_min_f32(self: Number, rhs: f32) Number {
        return switch (self) {
            .Defined => Number { .Defined = std.math.min(self.Defined, rhs) },
            else => Number.@"Undefined",
        };
    }

    pub fn or_else(self: Number, other: Number) Number {
        return switch (self) {
            .Defined => self,
            else => other,
        };
    }

    pub fn or_else_f32(self: Number, other: f32) f32 {
        return switch (self) {
            .Defined => self.Defined,
            else => other,
        };
    }
};

test "Number " {
    const n1 = Number{ .Defined = 10.0 };
    const n2 = Number.default();
    try testing.expect(n1.div(n2) == Number.@"Undefined");
    try testing.expect(std.meta.eql(n1.div(n1), Number.from(1.0)));
    try testing.expect(std.meta.eql(n1.mul(n1), Number.from(100)));
}

fn maybe_max_f32_number(lhs: f32, rhs: Number) f32 {
    return switch(rhs) {
       .Defined => std.math.max(lhs, rhs.Defined),
       else => lhs
    };
}

fn maybe_min_f32_number(lhs: f32, rhs: Number) f32 {
    return switch(rhs) {
       .Defined => std.math.min(lhs, rhs.Defined),
       else => lhs
    };
}
//#endregion number

//#region style

pub const AlignItems = enum {
    FlexStart,
    FlexEnd,
    Center,
    Baseline,
    Stretch,

    pub fn default() AlignItems {
        return .Stretch;
    }
};

pub const AlignSelf = enum {
    Auto,
    FlexStart,
    FlexEnd,
    Center,
    Baseline,
    Stretch,

    pub fn default() AlignSelf {
        return .Auto;
    }
};

pub const AlignContent = enum {
    FlexStart,
    FlexEnd,
    Center,
    Stretch,
    SpaceBetween,
    SpaceAround,

    pub fn default() AlignContent {
        return .Stretch;
    }
};

pub const Direction = enum {
    Inherit,
    LTR,
    RLT,

    pub fn default() Direction {
        return .Inherit;
    }
};

pub const Display = enum {
    Flex,
    None,

    pub fn default() Display {
        return .Flex;
    }
};

pub const FlexDirection = enum {
    Row,
    Column,
    RowReverse,
    ColumnReverse,

    pub fn default() FlexDirection {
        return .Row;
    }

    pub fn is_row(self: FlexDirection) bool {
        return (self == .Row) or (self == .RowReverse);
    }

    pub fn is_column(self: FlexDirection) bool {
        return (self == .Column) or (self == .ColumnReverse);
    }

    pub fn is_reverse(self: FlexDirection) bool {
        return (self == .RowReverse) or (self == .ColumnReverse);
    }
};

pub const JustifyContent = enum {
    FlexStart,
    FlexEnd,
    Center,
    SpaceBetween,
    SpaceAround,
    SpaceEvenly,

    pub fn default() JustifyContent {
        return .FlexStart;
    }
};

pub const Overflow = enum {
    Visible,
    Hidden,
    Scroll,

    pub fn default() Overflow {
        return .Visible;
    }
};

pub const PositionType = enum {
    Relative,
    Absolute,

    pub fn default() PositionType {
        return .Relative;
    }
};

pub const FlexWrap = enum {
    NoWrap,
    Wrap,
    WrapReverse,

    pub fn default() FlexWrap {
        return .NoWrap;
    }
};

pub const Dimension = union(enum) {
    Auto,
    @"Undefined",
    Points: f32,
    Percent: f32,

    pub fn default() Dimension {
        return .@"Undefined";
    }

    pub fn resolve(self: Dimension, parent_dim: Number) Number {
        return switch (self) {
            .Points => Number{ .Defined = self.Points },
            .Percent => parent_dim.mul_f32(self.Percent),
            else => Number.@"Undefined",
        };
    }

    pub fn is_defined(self: Dimension) bool {
        return (self == .Points) or (self == .Percent);
    }
};

test "Dimension" {
    const n1 = Number{ .Defined = 100.0 };
    const d1 = Dimension{ .Percent = 0.10 };
    try testing.expect(std.meta.eql(d1.resolve(n1), Number{ .Defined = 10.0 }));
    try testing.expect(d1.is_defined());
}

pub const Style = struct {
    const Self = @This();

    display: Display,
    position_type: PositionType,
    direction: Direction,
    flex_direction: FlexDirection,
    flex_wrap: FlexWrap,
    overflow: Overflow,
    align_items: AlignItems,
    align_self: AlignSelf,
    align_content: AlignContent,
    justify_content: JustifyContent,
    position: Rect(Dimension),
    margin: Rect(Dimension),
    padding: Rect(Dimension),
    border: Rect(Dimension),
    flex_grow: f32,
    flex_shrink: f32,
    flex_basis: Dimension,
    size: Size(Dimension),
    min_size: Size(Dimension),
    max_size: Size(Dimension),
    aspect_ratio: Number,

    pub fn default() Self {
        return Self{
            .display = Display.default(),
            .position_type = PositionType.default(),
            .direction = Direction.default(),
            .flex_direction = FlexDirection.default(),
            .flex_wrap = FlexWrap.default(),
            .overflow = Overflow.default(),
            .align_items = AlignItems.default(),
            .align_self = AlignSelf.default(),
            .align_content = AlignContent.default(),
            .justify_content = JustifyContent.default(),
            .position = Rect(Dimension).default(),
            .margin = Rect(Dimension).default(),
            .padding = Rect(Dimension).default(),
            .border = Rect(Dimension).default(),
            .flex_grow = 0.0,
            .flex_shrink = 1.0,
            .flex_basis = Dimension.default(),
            .size = Size(Dimension).default(),
            .min_size = Size(Dimension).default(),
            .max_size = Size(Dimension).default(),
            .aspect_ratio = Number.default(),
        };
    }

    pub fn min_main_size(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.min_size.width;
        } else {
            return self.min_size.height;
        }
    }

    pub fn max_min_size(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.max_size.width;
        } else {
            return self.max_size.height;
        }
    }

    pub fn main_margin_start(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.margin.start;
        } else {
            return self.margin.top;
        }
    }

    pub fn min_margin_end(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.margin.end;
        } else {
            return self.margin.bottom;
        }
    }

    pub fn cross_size(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.size.height;
        } else {
            return self.size.width;
        }
    }

    pub fn min_cross_size(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.min_size.height;
        } else {
            return self.min_size.width;
        }
    }

    pub fn max_cross_size(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.max_size.width;
        } else {
            return self.max_size.height;
        }
    }

    pub fn cross_margin_start(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.margin.top;
        } else {
            return self.margin.start;
        }
    }

    pub fn cross_margin_end(self: Self, direction: FlexDirection) Dimension {
        if (direction.is_row()) {
            return self.margin.bottom;
        } else {
            return self.margin.end;
        }
    }

    pub fn align_self_fn(self: Self, parent: *Style) AlignSelf {
        if (self.align_self == AlignSelf.Auto) {
            return switch (parent.*.align_items) {
                .FlexStart => AlignSelf.FlexStart,
                .FlexEnd => AlignSelf.FlexEnd,
                .Center => AlignSelf.Center,
                .Baseline => AlignSelf.Baseline,
                .Stretch => AlignSelf.Stretch,
            };
        } else {
            return self.align_self;
        }
    }
};

test "default style" {
    const s = Style.default();
    try std.testing.expect(s.display == Display.default());
    try std.testing.expect(s.position_type == PositionType.default());
    try std.testing.expect(s.direction == Direction.default());
    try std.testing.expect(s.flex_direction == FlexDirection.default());
    try std.testing.expect(s.flex_wrap == FlexWrap.default());
    try std.testing.expect(s.overflow == Overflow.default());
    try std.testing.expect(s.align_items == AlignItems.default());
    try std.testing.expect(s.align_self == AlignSelf.default());
    try std.testing.expect(s.align_content == AlignContent.default());
    try std.testing.expect(s.justify_content == JustifyContent.default());
    try std.testing.expect(std.meta.eql(s.position, Rect(Dimension).default()));
    try std.testing.expect(std.meta.eql(s.margin, Rect(Dimension).default()));
    try std.testing.expect(std.meta.eql(s.padding, Rect(Dimension).default()));
    try std.testing.expect(std.meta.eql(s.border, Rect(Dimension).default()));
    try std.testing.expect(s.flex_grow == 0.0);
    try std.testing.expect(s.flex_shrink == 1.0);
    try std.testing.expect(std.meta.eql(s.flex_basis, Dimension.default()));
    try std.testing.expect(std.meta.eql(s.size, Size(Dimension).default()));
    try std.testing.expect(std.meta.eql(s.min_size, Size(Dimension).default()));
    try std.testing.expect(std.meta.eql(s.max_size, Size(Dimension).default()));
    try std.testing.expect(std.meta.eql(s.aspect_ratio, Number.default()));
}

//#endregion style

//#region id

pub const NodeId = usize;

//#endregion id

//#region node

const MeasureFunction = fn (Size(Number)) Size(f32);

pub const MeasureFunc = union(enum) { Raw: MeasureFunction, Boxed: *MeasureFunction };

//#endregion node

//#region forest + algo

pub const NodeData = struct {
    const Self = @This();

    style: Style,
    measure: ?MeasureFunc,
    layout: Layout,
    layout_cache: ?Cache,
    is_dirty: bool,

    pub fn new_leaf(style: Style, measure: MeasureFunc) Self {
        return Self{
            .style = style,
            .measure = measure,
            .layout_cache = null,
            .layout = Layout.new(),
            .is_dirty = true,
        };
    }

    pub fn new(style: Style) Self {
        return Self{
            .style = style,
            .measure = null,
            .layout_cache = null,
            .layout = Layout.new(),
            .is_dirty = true,
        };
    }
};

pub const ComputeResult = struct {
    const Self = @This();

    size: Size(f32),

    pub fn clone(self: *Self) Self {
        return Self{ .size = Size(f32){
            .width = self.size.width,
            .height = self.size.height,
        } };
    }
};

fn echoMeasureFunc(s: Size(Number)) Size(f32) {
    return Size(f32){ .width = s.width.Defined, .height = s.height.Defined };
}

test "NodeData" {
    const leaf = NodeData.new_leaf(Style.default(), MeasureFunc{
        .Raw = echoMeasureFunc,
    });
    try std.testing.expect(leaf.is_dirty == true);
    try std.testing.expect(leaf.layout_cache == null);
    try std.testing.expect(std.meta.eql(leaf.style, Style.default()));
}

pub const Forest = struct {
    const Self = @This();

    const FlexItem = struct {
        node: NodeId,

        size: Size(Number),
        min_size: Size(Number),
        max_size: Size(Number),

        position: Rect(Number),
        margin: Rect(f32),
        padding: Rect(f32),
        border: Rect(f32),

        flex_basis: f32,
        inner_flex_basis: f32,
        violation: f32,
        frozen: bool,

        hypothetical_inner_size: Size(f32),
        hypothetical_outer_size: Size(f32),
        target_size: Size(f32),
        outer_target_size: Size(f32),

        baseline: f32,

        offset_main: f32,
        offset_cross: f32,
    };

    const Flexline = struct {
        items: []FlexItem,
        cross_size: f32,
        offset_cross: f32,
    };

    nodes: Vec(NodeData),
    children: Vec(ChildrenVec(NodeId)),
    parents: Vec(ParentsVec(NodeId)),
    allocator: Allocator,

    pub fn with_capacity(alloc: Allocator, capacity: usize) Allocator.Error!Self {
        return Self{
            .nodes = try Vec(NodeData).initCapacity(alloc, capacity),
            .children = try Vec(ChildrenVec(NodeId)).initCapacity(alloc, capacity),
            .parents = try Vec(ParentsVec(NodeId)).initCapacity(alloc, capacity),
            .allocator = alloc,
        };
    }

    pub fn new_leaf(self: *Self, style: Style, measure: MeasureFunc) Allocator.Error!NodeId {
        const id = self.nodes.items.len;
        try self.nodes.append(NodeData.new_leaf(style, measure));
        try self.children.append(try ChildrenVec(NodeId).initCapacity(self.allocator, @as(usize, 0)));
        try self.parents.append(try ParentsVec(NodeId).initCapacity(self.allocator, @as(usize, 1)));
        return id;
    }

    pub fn new_node(self: *Self, style: Style, children: ChildrenVec(NodeId)) Allocator.Error!NodeId {
        const id = self.nodes.items.len;
        for (children.items) |*child| {
            try self.parents.items[child.*].append(id);
        }
        try self.nodes.append(NodeData.new(style));
        try self.children.append(children);
        try self.parents.append(try ParentsVec(NodeId).initCapacity(self.allocator, @as(usize, 1)));
        return id;
    }

    pub fn add_child(self: *Self, node: NodeId, child: NodeId) Allocator.Error!void {
        try self.parents.items[child].append(node);
        try self.children.items[node].append(child);
        self.mark_dirty(node);
    }

    fn mark_dirty_impl(nodes: *Vec(NodeData), parents: []const ParentsVec(NodeId), node_id: NodeId) void {
        var node = &nodes.items[node_id];
        node.layout_cache = null;
        node.is_dirty = true;
        for (parents[node_id].items) |*parent| {
            mark_dirty_impl(nodes, parents, parent.*);
        }
    }

    pub fn mark_dirty(self: *Self, node: NodeId) void {
        mark_dirty_impl(&self.nodes, self.parents.items, node);
    }

    pub fn clear(_: *Self) void {
        unreachable;
    }

    fn clear_children_retaining_capacity(self: *Self) void {
        for (self.children.items) |*child| {
            child.deinit();
        }
        self.children.clearRetainingCapacity();
    }

    fn clear_parents_reatining_capacity(self: *Self) void {
        for (self.parents.items) |*parent| {
            parent.deinit();
        }
        self.parents.clearRetainingCapacity();
    }

    pub fn swap_remove(self: *Self, node: NodeId) ?NodeId {
        _ = self.nodes.swapRemove(node);
        if (self.nodes.items.len == 0) {
            self.clear_children_retaining_capacity();
            self.clear_parents_reatining_capacity();
            return null;
        }
        //  Remove old node as parent from all it's children.
        for (self.children.items[node].items) |*child| {
            var parents_child = &self.parents.items[child.*];
            var pos: usize = 0;
            while (pos < parents_child.items.len) {
                if (parents_child.items[pos] == node) {
                    _ = parents_child.swapRemove(pos);
                } else {
                    pos += 1;
                }
            }
        }
        //  Remove old node as child from all it's parents.
        for (self.parents.items[node].items) |*parent| {
            var child_parents = &self.children.items[parent.*];
            var pos: usize = 0;
            while (pos < child_parents.items.len) {
                if (child_parents.items[pos] == node) {
                    _ = child_parents.swapRemove(pos);
                } else {
                    pos += 1;
                }
            }
        }
        const last = self.nodes.items.len;
        if (last != node) {
            // Update ids for every child of the swapped in node.
            for (self.children.items[last].items) |*child| {
                for (self.parents.items[child.*].items) |*parent| {
                    if (parent.* == last) {
                        parent.* = node;
                    }
                }
            }
            // Update ids for every parent of the swapped in node
            for (self.parents.items[last].items) |*parent| {
                for (self.children.items[parent.*].items) |*child| {
                    if (child.* == last) {
                        child.* = node;
                    }
                }
            }
            self.children.swapRemove(node).deinit();
            self.parents.swapRemove(node).deinit();
            return last;
        } else {
            self.children.swapRemove(node).deinit();
            self.parents.swapRemove(node).deinit();
            return null;
        }
    }

    pub fn remove_child(self: *Self, node: NodeId, child: NodeId) Allocator.Error!NodeId {
        var index: NodeId = std.math.maxInt(NodeId);
        for (self.children.items[node].items) |*n, idx| {
            if (n.* == child) {
                index = idx;
                break;
            }
        }
        return self.remove_child_at_index(node, index);
    }

    pub fn remove_child_at_index(self: *Self, node: NodeId, index: usize) Allocator.Error!NodeId {
        const child = self.children.items[node].orderedRemove(index);
        var count: usize = 0;
        var new_vec = try ParentsVec(NodeId).initCapacity(self.allocator, self.parents.items[child].items.len);
        for (self.parents.items[child].items) |parent| {
            if (parent != node) {
                new_vec.appendAssumeCapacity(parent);
                count += 1;
            }
        }
        new_vec.shrinkAndFree(count);
        self.parents.items[child].deinit();
        self.parents.items[child] = new_vec;
        self.mark_dirty(node);
        return child;
    }

    pub fn compute_layout(self: *Self, node: NodeId, size: Size(Number)) !void {
        try self.compute(node, size);
    }

    pub fn compute(self: *Self, root: NodeId, size: Size(Number)) !void {
        const style = self.nodes.items[root].style;
        const has_root_min_max = style.min_size.width.is_defined() or style.min_size.height.is_defined() or style.max_size.width.is_defined() or style.max_size.height.is_defined();
        if (has_root_min_max) {} else {
            _ = try self.compute_internal(root, style.size.resolve(size), size, true);
        }
    }

    fn compute_internal(self: *Self, node: NodeId, node_size: Size(Number), parent_size: Size(Number), perform_layout: bool) Allocator.Error!ComputeResult {
        self.nodes.items[node].is_dirty = false;
        if (self.nodes.items[node].layout_cache) |*cache| {
            if (cache.perform_layout or !perform_layout) {
                const width_compatible = switch (node_size.width) {
                    .Defined => |width| std.math.approxEqAbs(f32, width, cache.result.size.width, std.math.f32_epsilon),
                    else => cache.node_size.width.is_undefined(),
                };
                const height_compatible = switch (node_size.height) {
                    .Defined => |height| std.math.approxEqAbs(f32, height, cache.result.size.height, std.math.f32_epsilon),
                    else => cache.node_size.height.is_undefined(),
                };
                if (width_compatible and height_compatible) {
                    return cache.result.clone();
                }
                if (sizeAreEqual(cache.node_size, node_size) and sizeAreEqual(cache.parent_size, parent_size)) {
                    return cache.result.clone();
                }
            }
        }
        std.debug.print("\n\n\n parent_size = {any} \n\n\n", .{ parent_size });
        const dir = self.nodes.items[node].style.flex_direction;
        const is_row = dir.is_row();
        const is_column = dir.is_column();
        //const is_wrap_reverse = self.nodes.items[node].style.flex_wrap == FlexWrap.WrapReverse;
        const widthMapper = &RectMapper(Dimension, f32){ .parent_size = parent_size.width, .default_value = 0.0 };
        const margin = self.nodes.items[node].style.margin.map(f32, widthMapper);
        const padding = self.nodes.items[node].style.padding.map(f32, widthMapper);
        const border = self.nodes.items[node].style.border.map(f32, widthMapper);

        const padding_border = Rect(f32){ .start = padding.start + border.start, .end = padding.end + border.end, .top = padding.top + border.top, .bottom = padding.bottom + border.bottom };

        const node_inner_size = Size(Number){
            .width = node_size.width.sub_f32(padding_border.horizontal()),
            .height = node_size.height.sub_f32(padding_border.vertical()),
        };

        //var container_size = ZeroSize();
        //var inner_container_size = ZeroSize();

        // if this a leaf node we can skip a lot this function in some cases
        if (self.children.items[node].items.len == 0) {
            if (node_size.width.is_defined() and node_size.height.is_defined()) {
                return ComputeResult{ .size = Size(f32){
                    .width = node_size.width.or_else_f32(0.0),
                    .height = node_size.height.or_else_f32(0.0),
                } };
            }

            if (self.nodes.items[node].measure) |*measure| {
                var result = switch (measure.*) {
                    .Raw => |measureFn| ComputeResult{ .size = measureFn(node_size) },
                    .Boxed => |measureFn| ComputeResult{ .size = measureFn.*(node_size) },
                };
                self.nodes.items[node].layout_cache = Cache{
                    .node_size = node_size,
                    .parent_size = parent_size,
                    .perform_layout = perform_layout,
                    .result = result.clone(),
                };
                return result;
            }
            return ComputeResult{ .size = Size(f32){
                .width = node_size.width.or_else_f32(0.0) + padding_border.horizontal(),
                .height = node_size.height.or_else_f32(0.0) + padding_border.vertical(),
            } };
        }
        
        // 9.2 Line Length Determination
        // 1. Generate anonymous flex items as described as 4 Flex Items.
        //

        const available_space = Size(Number){
            .width = node_size.width.or_else(parent_size.width.sub_f32(margin.horizontal())).sub_f32(padding_border.horizontal()),
            .height = node_size.height.or_else(parent_size.height.sub_f32(margin.vertical())).sub_f32(padding_border.vertical()),
        };
        var flex_items = Vec(FlexItem).init(self.allocator);
        const inner_size_width_mapper = &RectMapper(Dimension, f32){ .parent_size = node_inner_size.width, .default_value = 0.0 };
        var has_baseline_child = false;
        for (self.children.items[node].items) |child| {
            const child_style = &self.nodes.items[child].style;
            if (child_style.position_type != PositionType.Absolute and child_style.display != Display.None) {
                try flex_items.append(FlexItem{
                    .node = child,
                    .size = child_style.size.resolve(node_inner_size),
                    .min_size = child_style.min_size.resolve(node_inner_size),
                    .max_size = child_style.max_size.resolve(node_inner_size),
                    .position = Rect(Number){
                        .start = child_style.position.start.resolve(node_inner_size.width),
                        .end = child_style.position.end.resolve(node_inner_size.width),
                        .top = child_style.position.top.resolve(node_inner_size.width),
                        .bottom = child_style.position.bottom.resolve(node_inner_size.width),
                    },
                    .margin = child_style.margin.map(f32, inner_size_width_mapper),
                    .padding = child_style.margin.map(f32, inner_size_width_mapper),
                    .border = child_style.padding.map(f32, inner_size_width_mapper),
                    .flex_basis = 0.0,
                    .inner_flex_basis = 0.0,
                    .violation = 0.0,
                    .frozen = false,

                    .hypothetical_inner_size = ZeroSize(),
                    .hypothetical_outer_size = ZeroSize(),
                    .target_size = ZeroSize(),
                    .outer_target_size = ZeroSize(),

                    .baseline = 0.0,
                    .offset_main = 0.0,
                    .offset_cross = 0.0,
                });
                has_baseline_child = if (!has_baseline_child) child_style.align_self_fn(&self.nodes.items[node].style) == AlignSelf.Baseline else has_baseline_child;
            }
        }
        // 3. Determine the flex base size and hypothetical main size of each item:
        for (flex_items.items) |*child| {
            const child_style = &self.nodes.items[child.node].style;

            // A. If the item has a definite used flex basis, that's the flex base size.

            const flex_basis = child_style.flex_basis.resolve(node_inner_size.main(dir));
            if (flex_basis.is_defined()) {
                child.flex_basis = flex_basis.or_else_f32(0.0);
                continue;
            }

            // B. If the flex item has a intrinsic aspect ratio,
            //    a used flex basis of content and a definite cross size
            //    then the flex base size is calculated from it's inner
            //    cross size and the flex item's intrinsic aspect ratio.

            if (child_style.aspect_ratio == Number.Defined) {
                const cross = node_size.cross(dir);
                if (cross == Number.Defined) {
                    if (child_style.flex_basis == Dimension.Auto) {
                        child.flex_basis = cross.Defined * child_style.aspect_ratio.Defined;
                        continue;
                    }
                }
            }

            // C. If the used flex basis is content or depends on its available space,
            //    and the flex container is being sized under a min-content or max-content
            //    constraint (e.g. when performing automatic table layout [CSS21]),
            //    size the item under that constraint. The flex base size is the item’s
            //    resulting main size.

            // TODO - Probably need to cover this case in future

            // D. Otherwise, if the used flex basis is content or depends on its
            //    available space, the available main size is infinite, and the flex item’s
            //    inline axis is parallel to the main axis, lay the item out using the rules
            //    for a box in an orthogonal flow [CSS3-WRITING-MODES]. The flex base size
            //    is the item’s max-content main size.

            // TODO - Probably need to cover this case in future

            // E. Otherwise, size the item into the available space using its used flex basis
            //    in place of its main size, treating a value of content as max-content.
            //    If a cross size is needed to determine the main size (e.g. when the
            //    flex item’s main size is in its block axis) and the flex item’s cross size
            //    is auto and not definite, in this calculation use fit-content as the
            //    flex item’s cross size. The flex base size is the item’s resulting main size.

            const width: Number = if (child.size.width.is_defined() and
                child_style.align_self_fn(&self.nodes.items[node].style) == AlignSelf.Stretch and
                is_column) available_space.width else child.size.width;

            const height: Number = if (child.size.height.is_defined() and
                child_style.align_self_fn(&self.nodes.items[node].style) == AlignSelf.Stretch and
                is_row) available_space.height else child.size.height;

            const child_parent_size = Size(Number) {
                .width = width.maybe_max(child.min_size.width).maybe_min(child.max_size.width),
                .height = height.maybe_max(child.min_size.height).maybe_min(child.max_size.height),
            };
            
            std.debug.print("child_parent_size : {any}, available_space = {any} node_size = {any} node_inner_size = {any} \n", .{child_parent_size, available_space, node_size, node_inner_size});
            const child_flex_basis_size = try self.compute_internal(child.node, child_parent_size, available_space, false);
            child.flex_basis = maybe_min_f32_number(
                maybe_max_f32_number(child_flex_basis_size.size.main(dir), child.min_size.main(dir)),
                child.max_size.main(dir)
            );
        }

        // The hypothetical main size is the item’s flex base size clamped according to its
        // used min and max main sizes (and flooring the content box size at zero).

        for(flex_items.items) | *child | {
            child.inner_flex_basis = child.flex_basis - child.padding.main(dir) - child.border.main(dir);
            // TODO - not really spec abiding but needs to be done somewhere. probably somewhere else though.
            // The following logic was developed not from the spec but by trail and error looking into how
            // webkit handled various scenarios. Can probably be solved better by passing in
            // min-content max-content constraints from the top
            const min_main_size = try compute_internal(child.node, UndefinedSize(), available_space, false);
            const min_main = maybe_min_f32_number(
                maybe_max_f32_number(min_main_size.main(dir), child.min_size.main(dir)),
                child.size.main(dir)
            );
            
        }

        std.debug.print(" available_space = {} flex_items = {} \n", .{ available_space, flex_items });
        unreachable;
    }

    pub fn deinit(self: *Self) void {
        self.nodes.deinit();
        for (self.children.items) |*child| {
            child.deinit();
        }
        for (self.parents.items) |*parent| {
            parent.deinit();
        }
        self.children.deinit();
        self.parents.deinit();
    }
};

test "Forest" {
    {
        const test_allocator = std.testing.allocator;
        var forest = try Forest.with_capacity(test_allocator, 2);
        defer {
            forest.deinit();
        }
        const nodeId = forest.new_leaf(Style.default(), MeasureFunc{ .Raw = echoMeasureFunc });
        std.debug.print("\n forest.new_leaf = nodeId = {any}\n", .{nodeId});
    }
    {
        var forest = try Forest.with_capacity(std.testing.allocator, 2);
        defer forest.deinit();
        std.debug.print("\n1. forest.new_node (NodeId) = {any}\n", .{try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator))});
        std.debug.print("\n2. forest.new_node (NodeId) = {any}\n", .{try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator))});
    }
    {
        var forest = try Forest.with_capacity(std.testing.allocator, 2);
        defer forest.deinit();
        const node0 = try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator));
        const node1 = try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator));
        const node2 = try forest.new_leaf(Style.default(), MeasureFunc{ .Raw = echoMeasureFunc });
        try forest.add_child(node0, node1);
        forest.nodes.items[node0].is_dirty = false;
        forest.nodes.items[node1].is_dirty = false;
        try forest.add_child(node1, node2);
        try std.testing.expect(forest.nodes.items[node1].is_dirty);
        try std.testing.expect(forest.nodes.items[node0].is_dirty);
    }
}
test "Forest.swap_remove" {
    {
        std.debug.print("\n  When there is only one node in forest. \n", .{});
        var forest = try Forest.with_capacity(std.testing.allocator, 2);
        defer forest.deinit();
        const node0 = try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator));
        _ = forest.swap_remove(node0);
        try std.testing.expect(forest.nodes.items.len == 0);
    }
    {
        std.debug.print("  When there are multiple nodes in the forest. \n", .{});
        var forest = try Forest.with_capacity(std.testing.allocator, 4);
        defer forest.deinit();
        const node0 = try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator));
        const node1 = try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator));
        const node2 = try forest.new_leaf(Style.default(), MeasureFunc{ .Raw = echoMeasureFunc });
        try forest.add_child(node1, node2);
        try forest.add_child(node0, node1);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{0}, forest.parents.items[1].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{1}, forest.children.items[0].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{1}, forest.parents.items[2].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{2}, forest.children.items[1].items);
        _ = forest.swap_remove(node1);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{}, forest.children.items[0].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{}, forest.parents.items[1].items);
    }
    {
        std.debug.print("  When there are multiple nodes in the forest and removing the last node.\n", .{});
        var forest = try Forest.with_capacity(std.testing.allocator, 4);
        defer forest.deinit();
        const node0 = try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator));
        const node1 = try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator));
        const node2 = try forest.new_leaf(Style.default(), MeasureFunc{ .Raw = echoMeasureFunc });
        try forest.add_child(node1, node2);
        try forest.add_child(node0, node1);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{1}, forest.parents.items[2].items);
        _ = forest.swap_remove(node2);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{1}, forest.children.items[0].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{}, forest.parents.items[0].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{0}, forest.parents.items[1].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{}, forest.children.items[1].items);
        try std.testing.expect(forest.nodes.items.len == 2);
    }
}

test "Forest.remove_child" {
    {
        std.debug.print("  When removing child.\n", .{});
        var forest = try Forest.with_capacity(std.testing.allocator, 4);
        defer forest.deinit();
        const node0 = try forest.new_node(Style.default(), ChildrenVec(NodeId).init(std.testing.allocator));
        const node1 = try forest.new_leaf(Style.default(), MeasureFunc{ .Raw = echoMeasureFunc });
        const node2 = try forest.new_leaf(Style.default(), MeasureFunc{ .Raw = echoMeasureFunc });
        try forest.add_child(node0, node1);
        try forest.add_child(node0, node2);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{ 1, 2 }, forest.children.items[0].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{0}, forest.parents.items[2].items);
        _ = try forest.remove_child(@as(NodeId, 0), @as(NodeId, 2));
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{1}, forest.children.items[0].items);
        try std.testing.expectEqualSlices(NodeId, &[_]NodeId{}, forest.parents.items[2].items);
    }
}

test "Forest.compute_layout" {
    {
        std.debug.print("  Basic\n.", .{});
        var forest = try Forest.with_capacity(std.testing.allocator, 4);
        defer forest.deinit();
        const leaf_node = try forest.new_leaf(Style.default(), MeasureFunc{ .Raw = echoMeasureFunc });
        var child_vec = try ChildrenVec(NodeId).initCapacity(std.testing.allocator, 1);
        child_vec.appendAssumeCapacity(leaf_node);
        const root_node = try forest.new_node(Style.default(), child_vec);
        const parent_size = Size(Number){ .width = Number{ .Defined = 100.0 }, .height = Number{ .Defined = 100.0 } };
        forest.compute_layout(root_node, parent_size) catch {};
    }
}

//#endregion forest + algo

//#region result
pub const Layout = struct {
    const Self = @This();

    order: u32,
    size: Size(f32),
    location: Point(f32),

    pub fn new() Self {
        return Self{ .order = 0, .size = ZeroSize(), .location = ZeroPoint() };
    }
};

pub const Cache = struct {
    node_size: Size(Number),
    parent_size: Size(Number),
    perform_layout: bool,
    result: ComputeResult,
};

//#endregion result
