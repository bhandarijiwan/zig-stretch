const std = @import("std");
const testing = std.testing;

//#region Container
const Vec = std.ArrayList;
const Map = std.AutoHashMap;
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

        pub fn set_main(self: *Self, direction: FlexDirection, value: T) void {
            if (direction.is_row()) {
                self.width = value;
            } else {
                self.height = value;
            }
        }

        pub fn set_cross(self: *Self, direction: FlexDirection, value: T) void {
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
            .Defined => Number{ .Defined = std.math.min(self.Defined, rhs) },
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
    return switch (rhs) {
        .Defined => std.math.max(lhs, rhs.Defined),
        else => lhs,
    };
}

fn maybe_min_f32_number(lhs: f32, rhs: Number) f32 {
    return switch (rhs) {
        .Defined => std.math.min(lhs, rhs.Defined),
        else => lhs,
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
    RTL,

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

    pub fn max_main_size(self: Self, direction: FlexDirection) Dimension {
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

    pub fn main_margin_end(self: Self, direction: FlexDirection) Dimension {
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
            return switch (parent.align_items) {
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
pub const Id = usize;

const IdAllocator = struct {
    const Self = @This();

    new_id: std.atomic.Atomic(usize),

    pub fn new() Self {
        return Self{
            .new_id = std.atomic.Atomic(usize).init(0),
        };
    }

    pub fn allocate(self: *Self) Id {
        return self.new_id.fetchAdd(1, .Monotonic);
    }

    pub fn free(_: *Self, _: []Id) void {}
};

//#endregion id

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

    const FlexLine = struct {
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

    fn remove_parent_of_node(self: *Self, node: NodeId, parent_to_remove: NodeId) Allocator.Error!void {
        var count: usize = 0;
        var new_vec = try ParentsVec(NodeId).initCapacity(self.allocator, self.parents.items[node].items.len);
        for (self.parents.items[node].items) |parent| {
            if (parent != parent_to_remove) {
                new_vec.appendAssumeCapacity(parent);
                count += 1;
            }
        }
        new_vec.shrinkAndFree(count);
        self.parents.items[node].deinit();
        self.parents.items[node] = new_vec;
    }

    pub fn remove_child_at_index(self: *Self, node: NodeId, index: usize) Allocator.Error!NodeId {
        const child = self.children.items[node].orderedRemove(index);
        try self.remove_parent_of_node(child, node);
        self.mark_dirty(node);
        return child;
    }

    pub fn compute_layout(self: *Self, node: NodeId, size: Size(Number)) !void {
        std.log.info("compute_layout\n", .{});
        try self.compute(node, size);
    }

    pub fn compute(self: *Self, root: NodeId, size: Size(Number)) !void {
        const style = &self.nodes.items[root].style;
        const has_root_min_max = style.min_size.width.is_defined() or style.min_size.height.is_defined() or style.max_size.width.is_defined() or style.max_size.height.is_defined();
        var result: ComputeResult = undefined;
        if (has_root_min_max) {
            const first_pass = try self.compute_internal(root, style.size.resolve(size), size, false);
            const next_pass_width = maybe_min_f32_number(maybe_max_f32_number(first_pass.size.width, style.min_size.width.resolve(size.width)), style.max_size.width.resolve(size.width));
            const next_pass_height = maybe_min_f32_number(maybe_max_f32_number(first_pass.size.height, style.min_size.height.resolve(size.height)), style.max_size.height.resolve(size.height));
            result = try self.compute_internal(root, Size(Number){ .width = Number.from(next_pass_width), .height = Number.from(next_pass_height) }, size, true);
        } else {
            result = try self.compute_internal(root, style.size.resolve(size), size, true);
        }
        self.nodes.items[root].layout = Layout{
            .order = @as(u32, 0),
            .size = result.size,
            .location = ZeroPoint(),
        };
        round_layout(self.nodes.items, self.children.items, root, 0.0, 0.0);
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
        const dir = self.nodes.items[node].style.flex_direction;
        const is_row = dir.is_row();
        const is_column = dir.is_column();
        const is_wrap_reverse = self.nodes.items[node].style.flex_wrap == FlexWrap.WrapReverse;
        const widthMapper = &RectMapper(Dimension, f32){ .parent_size = parent_size.width, .default_value = 0.0 };
        const margin = self.nodes.items[node].style.margin.map(f32, widthMapper);
        const padding = self.nodes.items[node].style.padding.map(f32, widthMapper);
        const border = self.nodes.items[node].style.border.map(f32, widthMapper);

        const padding_border = Rect(f32){ .start = padding.start + border.start, .end = padding.end + border.end, .top = padding.top + border.top, .bottom = padding.bottom + border.bottom };

        const node_inner_size = Size(Number){
            .width = node_size.width.sub_f32(padding_border.horizontal()),
            .height = node_size.height.sub_f32(padding_border.vertical()),
        };

        var container_size = ZeroSize();
        var inner_container_size = ZeroSize();

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
        defer flex_items.deinit();
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

            const width: Number = if (!child.size.width.is_defined() and
                child_style.align_self_fn(&self.nodes.items[node].style) == AlignSelf.Stretch and
                is_column) available_space.width else child.size.width;

            const height: Number = if (!child.size.height.is_defined() and
                child_style.align_self_fn(&self.nodes.items[node].style) == AlignSelf.Stretch and
                is_row) available_space.height else child.size.height;

            const child_parent_size = Size(Number){
                .width = width.maybe_max(child.min_size.width).maybe_min(child.max_size.width),
                .height = height.maybe_max(child.min_size.height).maybe_min(child.max_size.height),
            };
            const child_flex_basis_size = try self.compute_internal(child.node, child_parent_size, available_space, false);
            child.flex_basis = maybe_min_f32_number(maybe_max_f32_number(child_flex_basis_size.size.main(dir), child.min_size.main(dir)), child.max_size.main(dir));
        }

        // The hypothetical main size is the item’s flex base size clamped according to its
        // used min and max main sizes (and flooring the content box size at zero).

        for (flex_items.items) |*child| {
            child.inner_flex_basis = child.flex_basis - child.padding.main(dir) - child.border.main(dir);

            // TODO - not really spec abiding but needs to be done somewhere. probably somewhere else though.
            // The following logic was developed not from the spec but by trail and error looking into how
            // webkit handled various scenarios. Can probably be solved better by passing in
            // min-content max-content constraints from the top

            const min_main_size = try self.compute_internal(child.node, UndefinedSize(), available_space, false);
            const min_main = maybe_min_f32_number(maybe_max_f32_number(min_main_size.size.main(dir), child.min_size.main(dir)), child.size.main(dir));
            const min_main_num = Number.from(min_main);
            const hypothetical_inner_size = maybe_min_f32_number(maybe_max_f32_number(child.flex_basis, min_main_num), child.max_size.main(dir));
            child.hypothetical_inner_size.set_main(dir, hypothetical_inner_size);
            child.hypothetical_outer_size.set_main(dir, hypothetical_inner_size + child.margin.main(dir));
        }
        // 9.3. Main Size Determination

        // 5. Collect flex items into flex lines:
        //    - If the flex container is single-line, collect all the flex items into
        //      a single flex line.
        //    - Otherwise, starting from the first uncollected item, collect consecutive
        //      items one by one until the first time that the next collected item would
        //      not fit into the flex container’s inner main size (or until a forced break
        //      is encountered, see §10 Fragmenting Flex Layout). If the very first
        //      uncollected item wouldn’t fit, collect just it into the line.
        //
        //      For this step, the size of a flex item is its outer hypothetical main size. (Note: This can be negative.)
        //      Repeat until all flex items have been collected into flex lines
        //
        //      Note that the "collect as many" line will collect zero-sized flex items onto
        //      the end of the previous line even if the last non-zero item exactly "filled up" the line.

        var flex_lines = blk: {
            var lines = try Vec(FlexLine).initCapacity(self.allocator, @as(usize, 1));
            if (self.nodes.items[node].style.flex_wrap == FlexWrap.NoWrap) {
                try lines.append(FlexLine{ .items = flex_items.items, .cross_size = 0.0, .offset_cross = 0.0 });
            } else {
                var flex_items_slice = flex_items.items;
                while (flex_items_slice.len > 0) {
                    var line_length: f32 = 0.0;
                    var index = flex_items_slice.len;
                    for (flex_items_slice) |*child, idx| {
                        line_length += child.hypothetical_outer_size.main(dir);
                        const available_space_main = available_space.main(dir);
                        if (available_space_main == Number.Defined) {
                            if (line_length > available_space_main.Defined and idx != 0) {
                                index = idx;
                                break;
                            }
                        }
                    }
                    try lines.append(FlexLine{ .items = flex_items_slice[0..index], .cross_size = 0.0, .offset_cross = 0.0 });
                    flex_items_slice = flex_items_slice[index..];
                }
            }
            break :blk lines;
        };
        defer flex_lines.deinit();
        // 6. Resolve the flexible lengths of all the flex items to find their used main size.
        //    See §9.7 Resolving Flexible Lengths.
        //
        // 9.7. Resolving Flexible Lengths
        for (flex_lines.items) |*line| {
            // 1. Determine the used flex factor. Sum the outer hypothetical main sizes of all
            //    items on the line. If the sum is less than the flex container’s inner main size,
            //    use the flex grow factor for the rest of this algorithm; otherwise, use the
            //    flex shrink factor.

            var use_flex_factor: f32 = 0.0;
            for (line.items) |*child| {
                use_flex_factor += child.hypothetical_outer_size.main(dir);
            }
            const growing = use_flex_factor < node_inner_size.main(dir).or_else_f32(0.0);
            const shrinking = !growing;

            // 2. Size inflexible items. Freeze, setting its target main size to its hypothetical main size
            //    - Any item that has a flex factor of zero
            //    - If using the flex grow factor: any item that has a flex base size
            //      greater than its hypothetical main size
            //    - If using the flex shrink factor: any item that has a flex base size
            //      smaller than its hypothetical main size

            // 3. Calculate initial free space. Sum the outer sizes of all items on the line,
            //    and subtract this from the flex container’s inner main size. For frozen items,
            //    use their outer target main size; for other items, use their outer flex base size.

            var used_space: f32 = 0.0;
            for (line.items) |*child| {
                //std.debug.print(" child.size.width = {s} child.min_size.width = {s} \n ", .{ @typeName(@TypeOf(child.size)), @typeName(@TypeOf(child.min_size.width))});
                if (node_inner_size.main(dir).is_undefined() and is_row) {
                    // zig fmt: off
                    const child_target = try self.compute_internal(
                        child.node,
                        Size(Number){ 
                            .width = child.size.width.maybe_max(child.min_size.width).maybe_min(child.max_size.width),
                            .height = child.size.height.maybe_max(child.min_size.height).maybe_min(child.max_size.height) 
                        },
                        available_space,
                        false
                    );
                    child.target_size.set_main(
                        dir,
                        maybe_min_f32_number(
                            maybe_max_f32_number(child_target.size.main(dir), child.min_size.main(dir)),
                            child.max_size.main(dir)
                        )
                    );
                    // zig fmt: on
                } else {
                    child.target_size.set_main(dir, child.hypothetical_inner_size.main(dir));
                }
                // TODO this should really only be set inside the if-statement below but
                // that causes the target_main_size to never be set for some items
                child.outer_target_size.set_main(dir, child.target_size.main(dir) + child.margin.main(dir));
                const child_style = &self.nodes.items[child.node].style;

                // zig fmt: off
                used_space += child.margin.main(dir);
                if (
                    (child_style.flex_grow == 0.0 and child_style.flex_shrink == 0.0) or
                    (growing and child.flex_basis > child.hypothetical_inner_size.main(dir)) or
                    (shrinking and child.flex_basis < child.hypothetical_inner_size.main(dir))
                ) {
                    child.frozen = true;
                    used_space += child.target_size.main(dir);
                } else {
                    used_space += child.flex_basis;
                }
            }
            // zig fmt: on

            const initial_free_space = node_inner_size.main(dir).sub_f32(used_space).or_else_f32(0.0);

            // 4. Loop

            while (true) {
                // a. Check for flexible items. If all the flex items on the line are frozen,
                //    free space has been distributed; exit this loop.
                for (line.items) |*child_line_item| {
                    if (!child_line_item.frozen) {
                        break;
                    }
                } else {
                    break;
                }
                // b. Calculate the remaining free space as for initial free space, above.
                //    If the sum of the unfrozen flex items’ flex factors is less than one,
                //    multiply the initial free space by this sum. If the magnitude of this
                //    value is less than the magnitude of the remaining free space, use this
                //    as the remaining free space.
                used_space = 0.0;
                for (line.items) |*child_line_item| {
                    used_space += child_line_item.margin.main(dir) + if (child_line_item.frozen) child_line_item.target_size.main(dir) else child_line_item.flex_basis;
                }
                var unfrozen = Vec(*FlexItem).init(self.allocator);
                defer unfrozen.deinit();
                for (line.items) |*child_line_item| {
                    if (!child_line_item.frozen) {
                        try unfrozen.append(child_line_item);
                    }
                }
                var sum_flex_grow: f32 = 0.0;
                var sum_flex_shrink: f32 = 0.0;
                for (unfrozen.items) |unfrozen_child| {
                    const unfrozen_child_style = &self.nodes.items[unfrozen_child.node].style;
                    sum_flex_grow += unfrozen_child_style.flex_grow;
                    sum_flex_shrink += unfrozen_child_style.flex_shrink;
                }
                var free_space: f32 = 0.0;
                if (growing and sum_flex_grow < 1.0) {
                    free_space = maybe_min_f32_number(initial_free_space * sum_flex_grow, node_inner_size.main(dir).sub_f32(used_space));
                } else if (shrinking and sum_flex_shrink < 1.0) {
                    free_space = maybe_max_f32_number(initial_free_space * sum_flex_shrink, node_inner_size.main(dir).sub_f32(used_space));
                } else {
                    free_space = node_inner_size.main(dir).sub_f32(used_space).or_else_f32(0.0);
                }

                // c. Distribute free space proportional to the flex factors.
                //    - If the remaining free space is zero
                //        Do Nothing
                //    - If using the flex grow factor
                //        Find the ratio of the item’s flex grow factor to the sum of the
                //        flex grow factors of all unfrozen items on the line. Set the item’s
                //        target main size to its flex base size plus a fraction of the remaining
                //        free space proportional to the ratio.
                //    - If using the flex shrink factor
                //        For every unfrozen item on the line, multiply its flex shrink factor by
                //        its inner flex base size, and note this as its scaled flex shrink factor.
                //        Find the ratio of the item’s scaled flex shrink factor to the sum of the
                //        scaled flex shrink factors of all unfrozen items on the line. Set the item’s
                //        target main size to its flex base size minus a fraction of the absolute value
                //        of the remaining free space proportional to the ratio. Note this may result
                //        in a negative inner main size; it will be corrected in the next step.
                //    - Otherwise
                //        Do Nothing

                if (std.math.isNormal(free_space)) {
                    if (growing and sum_flex_grow > 0.0) {
                        for (unfrozen.items) |unfrozen_child| {
                            unfrozen_child.target_size.set_main(dir, unfrozen_child.flex_basis + (free_space * (self.nodes.items[unfrozen_child.node].style.flex_grow / sum_flex_grow)));
                        }
                    } else if (shrinking and sum_flex_shrink > 0.0) {
                        var sum_scaled_shrink_factor: f32 = 0.0;
                        for (unfrozen.items) |unfrozen_child| {
                            sum_scaled_shrink_factor += unfrozen_child.inner_flex_basis * self.nodes.items[unfrozen_child.node].style.flex_shrink;
                        }
                        if (sum_scaled_shrink_factor > 0.0) {
                            for (unfrozen.items) |unfrozen_child| {
                                const scaled_shrink_factor = unfrozen_child.inner_flex_basis * self.nodes.items[unfrozen_child.node].style.flex_shrink;
                                unfrozen_child.target_size.set_main(dir, unfrozen_child.flex_basis + free_space * (scaled_shrink_factor / sum_scaled_shrink_factor));
                            }
                        }
                    }
                }

                // d. Fix min/max violations. Clamp each non-frozen item’s target main size by its
                //    used min and max main sizes and floor its content-box size at zero. If the
                //    item’s target main size was made smaller by this, it’s a max violation.
                //    If the item’s target main size was made larger by this, it’s a min violation.

                var total_violation: f32 = 0.0;
                for (unfrozen.items) |unfrozen_child| {
                    // TODO - not really spec abiding but needs to be done somewhere. probably somewhere else though.
                    // The following logic was developed not from the spec but by trail and error looking into how
                    // webkit handled various scenarios. Can probably be solved better by passing in
                    // min-content max-content constraints from the top. Need to figure out correct thing to do here as
                    // just piling on more conditionals.

                    var unfrozen_min_main: Number = undefined;
                    if (is_row and self.nodes.items[unfrozen_child.node].measure == null) {
                        const unfrozen_child_layout = try self.compute_internal(unfrozen_child.node, UndefinedSize(), available_space, false);
                        unfrozen_min_main = Number.from(maybe_max_f32_number(maybe_min_f32_number(unfrozen_child_layout.size.width, unfrozen_child.size.width), unfrozen_child.min_size.width));
                    } else {
                        unfrozen_min_main = unfrozen_child.min_size.main(dir);
                    }

                    const unfrozen_max_main = unfrozen_child.max_size.main(dir);
                    const clamped = std.math.max(0.0, maybe_max_f32_number(maybe_min_f32_number(unfrozen_child.target_size.main(dir), unfrozen_max_main), unfrozen_min_main));
                    const unfrozen_child_violation = clamped - unfrozen_child.target_size.main(dir);
                    unfrozen_child.violation = unfrozen_child_violation;
                    unfrozen_child.target_size.set_main(dir, clamped);
                    unfrozen_child.outer_target_size.set_main(dir, unfrozen_child.target_size.main(dir) + unfrozen_child.margin.main(dir));
                    total_violation += unfrozen_child_violation;
                }
                // e. Freeze over-flexed items. The total violation is the sum of the adjustments
                //    from the previous step ∑(clamped size - unclamped size). If the total violation is:
                //    - Zero
                //        Freeze all items.
                //    - Positive
                //        Freeze all the items with min violations.
                //    - Negative
                //        Freeze all the items with max violations.

                for (unfrozen.items) |unfrozen_child| {
                    if (total_violation > 0.0) {
                        unfrozen_child.frozen = unfrozen_child.violation > 0.0;
                    } else if (total_violation < 0.0) {
                        unfrozen_child.frozen = unfrozen_child.violation < 0.0;
                    } else {
                        unfrozen_child.frozen = true;
                    }
                }
                // f. Return to the start of this loop.
            }
        }

        // Not part of the spec from what i can see but seems correct
        container_size.set_main(dir, node_size.main(dir).or_else_f32(blk: {
            var longest_line: f32 = 0.0;
            for (flex_lines.items) |*line| {
                var line_length: f32 = 0.0;
                for (line.items) |*item| {
                    line_length += item.outer_target_size.main(dir);
                }
                longest_line = std.math.max(longest_line, line_length);
            }
            const size = longest_line + padding_border.main(dir);
            break :blk switch (available_space.main(dir)) {
                .Defined => |val| if (flex_lines.items.len > 1 and size < val) val else size,
                else => size,
            };
        }));
        inner_container_size.set_main(dir, container_size.main(dir) - padding_border.main(dir));

        // 9.4. Cross Size Determination

        // 7. Determine the hypothetical cross size of each item by performing layout with the
        //    used main size and the available space, treating auto as fit-content.

        for (flex_lines.items) |*line| {
            for (line.items) |*child| {
                const child_cross = child.size.cross(dir).maybe_max(child.min_size.cross(dir)).maybe_min(child.max_size.cross(dir));
                // zig fmt: off
                const child_computed_layout = try self.compute_internal(
                    child.node,
                    Size(Number) {
                        .width = if (is_row) Number.from(child.target_size.width) else child_cross,
                        .height = if (is_row) child_cross else Number.from(child.target_size.height)
                    },
                    Size(Number) {
                        .width = if (is_row) Number.from(container_size.main(dir)) else available_space.width,
                        .height = if (is_row) available_space.height else Number.from(container_size.main(dir))
                    },
                    false
                );
                child.hypothetical_inner_size.set_cross(
                    dir,
                    maybe_min_f32_number(
                        maybe_max_f32_number(
                            child_computed_layout.size.cross(dir),
                            child.min_size.cross(dir),
                        ),
                        child.max_size.cross(dir)
                    )
                );
                child.hypothetical_outer_size.set_cross(dir, child.hypothetical_inner_size.cross(dir) + child.margin.cross(dir));
                // zig fmt: on
            }
        }

        if (has_baseline_child) {
            for (flex_lines.items) |*line| {
                for (line.items) |*child| {
                    // zig fmt: off
                    const result = try self.compute_internal(
                        child.node,
                        Size(Number) {
                            .width = if (is_row) Number.from(child.target_size.width) else Number.from(child.hypothetical_inner_size.width),
                            .height = if (is_row) Number.from(child.hypothetical_inner_size.height) else Number.from(child.target_size.height)
                        },
                        Size(Number) {
                            .width = if (is_row) Number.from(container_size.width) else node_size.width,
                            .height = if (is_row) node_size.height else Number.from(container_size.height)
                        },
                        true
                    );
                    const order = for(self.children.items[node].items) | n, idx | {
                        if (n == child.node) {
                            break idx;
                        }
                    } else { unreachable; };

                    child.baseline = calc_baseline(self, child.node, &Layout {
                        .order = @truncate(u32, order),
                        .size = result.size,
                        .location = ZeroPoint(),
                    });
                    // zig fmt: on
                }
            }
        }

        // 8. Calculate the cross size of each flex line.
        //    If the flex container is single-line and has a definite cross size, the cross size
        //    of the flex line is the flex container’s inner cross size. Otherwise, for each flex line:
        //
        //    If the flex container is single-line, then clamp the line’s cross-size to be within
        //    the container’s computed min and max cross sizes. Note that if CSS 2.1’s definition
        //    of min/max-width/height applied more generally, this behavior would fall out automatically.

        if (flex_lines.items.len == 1 and node_size.cross(dir).is_defined()) {
            flex_lines.items[0].cross_size = (node_size.cross(dir).sub_f32(padding_border.cross(dir))).or_else_f32(0.0);
        } else {
            for (flex_lines.items) |*line| {
                //    1. Collect all the flex items whose inline-axis is parallel to the main-axis, whose
                //       align-self is baseline, and whose cross-axis margins are both non-auto. Find the
                //       largest of the distances between each item’s baseline and its hypothetical outer
                //       cross-start edge, and the largest of the distances between each item’s baseline
                //       and its hypothetical outer cross-end edge, and sum these two values.

                //    2. Among all the items not collected by the previous step, find the largest
                //       outer hypothetical cross size.

                //    3. The used cross-size of the flex line is the largest of the numbers found in the
                //       previous two steps and zero.
                var max_baseline: f32 = 0.0;
                for (line.items) |*child| {
                    max_baseline = std.math.max(max_baseline, child.baseline);
                }
                var line_cross_size: f32 = 0.0;
                for (line.items) |*child| {
                    const child_style = &self.nodes.items[child.node].style;
                    // zig fmt: off
                    if (
                        child_style.align_self_fn(&self.nodes.items[node].style) == AlignSelf.Baseline and
                        child_style.cross_margin_start(dir) != Dimension.Auto and
                        child_style.cross_margin_end(dir) != Dimension.Auto and
                        child_style.cross_size(dir) == Dimension.Auto
                    )  {
                        line_cross_size = std.math.max(
                            line_cross_size,
                            max_baseline - child.baseline + child.hypothetical_outer_size.cross(dir)
                        );
                    } else {
                        line_cross_size = std.math.max(
                            line_cross_size,
                            child.hypothetical_outer_size.cross(dir)
                        );
                    }
                    // zig fmt: on
                }
                line.cross_size = line_cross_size;
            }
        }

        // 9. Handle 'align-content: stretch'. If the flex container has a definite cross size,
        //    align-content is stretch, and the sum of the flex lines' cross sizes is less than
        //    the flex container’s inner cross size, increase the cross size of each flex line
        //    by equal amounts such that the sum of their cross sizes exactly equals the
        //    flex container’s inner cross size.

        if (self.nodes.items[node].style.align_content == AlignContent.Stretch and node_size.cross(dir).is_defined()) {
            const total_cross: f32 = blk: {
                var s: f32 = 0;
                for (flex_lines.items) |*line| {
                    s += line.cross_size;
                }
                break :blk s;
            };
            const inner_cross = (node_size.cross(dir).sub_f32(padding_border.cross(dir))).or_else_f32(0.0);
            if (total_cross < inner_cross) {
                const remaining = inner_cross - total_cross;
                const addition = remaining / @intToFloat(f32, flex_lines.items.len);
                for (flex_lines.items) |*line| {
                    line.cross_size += addition;
                }
            }
        }

        // 10. Collapse visibility:collapse items. If any flex items have visibility: collapse,
        //     note the cross size of the line they’re in as the item’s strut size, and restart
        //     layout from the beginning.
        //
        //     In this second layout round, when collecting items into lines, treat the collapsed
        //     items as having zero main size. For the rest of the algorithm following that step,
        //     ignore the collapsed items entirely (as if they were display:none) except that after
        //     calculating the cross size of the lines, if any line’s cross size is less than the
        //     largest strut size among all the collapsed items in the line, set its cross size to
        //     that strut size.
        //
        //     Skip this step in the second layout round.

        // TODO implement once (if ever) we support visibility:collapse

        // 11. Determine the used cross size of each flex item. If a flex item has align-self: stretch,
        //     its computed cross size property is auto, and neither of its cross-axis margins are auto,
        //     the used outer cross size is the used cross size of its flex line, clamped according to
        //     the item’s used min and max cross sizes. Otherwise, the used cross size is the item’s
        //     hypothetical cross size.
        //
        //     If the flex item has align-self: stretch, redo layout for its contents, treating this
        //     used size as its definite cross size so that percentage-sized children can be resolved.
        //
        //     Note that this step does not affect the main size of the flex item, even if it has an
        //     intrinsic aspect ratio.

        for (flex_lines.items) |*line| {
            const line_cross_size = line.cross_size;
            for (line.items) |*child| {
                const child_style = &self.nodes.items[child.node].style;
                var child_cross = child.hypothetical_inner_size.cross(dir);
                // zig fmt: off
                if (
                    child_style.align_self_fn(&self.nodes.items[node].style) == AlignSelf.Stretch and
                    child_style.cross_margin_start(dir) != Dimension.Auto and
                    child_style.cross_margin_end(dir) != Dimension.Auto and
                    child_style.cross_size(dir) == Dimension.Auto
                ) {
                    child_cross = maybe_min_f32_number(
                        maybe_max_f32_number(
                            line_cross_size - child.margin.cross(dir),
                            child.min_size.cross(dir)
                        ),
                        child.max_size.cross(dir)
                    );
                }
                child.target_size.set_cross(dir, child_cross);
                child.outer_target_size.set_cross(dir, child_cross + child.margin.cross(dir));
                // zig fmt: on
            }
        }
        // 9.5. Main-Axis Alignment

        // 12. Distribute any remaining free space. For each flex line:
        //     1. If the remaining free space is positive and at least one main-axis margin on this
        //        line is auto, distribute the free space equally among these margins. Otherwise,
        //        set all auto margins to zero.
        //     2. Align the items along the main-axis per justify-content.

        for (flex_lines.items) |*line| {
            var used_space: f32 = 0.0;
            for (line.items) |*child| {
                used_space += child.outer_target_size.main(dir);
            }
            const free_space = inner_container_size.main(dir) - used_space;
            var num_auto_margins: u32 = 0;
            for (line.items) |*child| {
                const child_style = &self.nodes.items[child.node].style;
                if (child_style.main_margin_start(dir) == Dimension.Auto) {
                    num_auto_margins += 1;
                }
                if (child_style.main_margin_end(dir) == Dimension.Auto) {
                    num_auto_margins += 1;
                }
            }

            if (free_space > 0.0 and num_auto_margins > 0) {
                const child_margin = free_space / @intToFloat(f32, num_auto_margins);
                for (line.items) |*child| {
                    const child_style = &self.nodes.items[child.node].style;
                    if (child_style.main_margin_start(dir) == Dimension.Auto) {
                        if (is_row) {
                            child.margin.start = child_margin;
                        } else {
                            child.margin.top = child_margin;
                        }
                    }
                    if (child_style.main_margin_end(dir) == Dimension.Auto) {
                        if (is_row) {
                            child.margin.end = child_margin;
                        } else {
                            child.margin.bottom = child_margin;
                        }
                    }
                }
            } else {
                const num_items = line.items.len;
                const layout_reverse = dir.is_reverse();
                var index_dir: isize = 1;
                var start_index: isize = 0;
                if (layout_reverse and line.items.len > 0) {
                    index_dir = -1;
                    start_index = @intCast(isize, line.items.len - 1);
                }
                var child_index = start_index;
                const node_justify_content = self.nodes.items[node].style.justify_content;
                while (child_index >= 0 and child_index < line.items.len) : (child_index += index_dir) {
                    const is_first = child_index == start_index;
                    var child = &line.items[@intCast(usize, child_index)];
                    child.offset_main = switch (node_justify_content) {
                        .FlexStart => if (layout_reverse and is_first) free_space else 0.0,
                        .Center => if (is_first) free_space / 2.0 else 0.0,
                        .FlexEnd => if (is_first and !layout_reverse) free_space else 0.0,
                        .SpaceBetween => if (is_first) 0.0 else free_space / @intToFloat(f32, (num_items - 1)),
                        .SpaceAround => if (is_first) (free_space / @intToFloat(f32, num_items)) / 2.0 else free_space / @intToFloat(f32, num_items),
                        .SpaceEvenly => free_space / @intToFloat(f32, num_items + 1),
                    };
                }
            }
        }

        // 9.6. Cross-Axis Alignment

        // 13. Resolve cross-axis auto margins. If a flex item has auto cross-axis margins:
        //     - If its outer cross size (treating those auto margins as zero) is less than the
        //       cross size of its flex line, distribute the difference in those sizes equally
        //       to the auto margins.
        //     - Otherwise, if the block-start or inline-start margin (whichever is in the cross axis)
        //       is auto, set it to zero. Set the opposite margin so that the outer cross size of the
        //       item equals the cross size of its flex line.

        for (flex_lines.items) |*line| {
            const line_cross_size = line.cross_size;
            var max_baseline: f32 = 0.0;
            for (line.items) |*child| {
                max_baseline = std.math.max(max_baseline, child.baseline);
            }

            for (line.items) |*child| {
                const free_space = line_cross_size - child.outer_target_size.cross(dir);
                const child_style = &self.nodes.items[child.node].style;
                if (child_style.cross_margin_start(dir) == Dimension.Auto and child_style.cross_margin_end(dir) == Dimension.Auto) {
                    if (is_row) {
                        child.margin.top = free_space / 2.0;
                        child.margin.bottom = free_space / 2.0;
                    } else {
                        child.margin.start = free_space / 2.0;
                        child.margin.end = free_space / 2.0;
                    }
                } else if (child_style.cross_margin_end(dir) == Dimension.Auto) {
                    if (is_row) {
                        child.margin.top = free_space;
                    } else {
                        child.margin.start = free_space;
                    }
                } else if (child_style.cross_margin_end(dir) == Dimension.Auto) {
                    if (is_row) {
                        child.margin.bottom = free_space;
                    } else {
                        child.margin.end = free_space;
                    }
                } else {
                    child.offset_cross = switch (child_style.align_self_fn(&self.nodes.items[node].style)) {
                        .Auto => 0.0, // Should never happen
                        .FlexStart => if (is_wrap_reverse) free_space else 0.0,
                        .FlexEnd => if (is_wrap_reverse) 0.0 else free_space,
                        .Center => free_space / 2.0,
                        .Baseline => if (is_row) max_baseline - child.baseline else if (is_wrap_reverse) free_space else 0.0,
                        .Stretch => if (is_wrap_reverse) free_space else 0.0,
                    };
                }
            }
        }

        // 15. Determine the flex container’s used cross size:
        //     - If the cross size property is a definite size, use that, clamped by the used
        //       min and max cross sizes of the flex container.
        //     - Otherwise, use the sum of the flex lines' cross sizes, clamped by the used
        //       min and max cross sizes of the flex container.

        const total_cross_size: f32 = blk: {
            var s: f32 = 0.0;
            for (flex_lines.items) |*line| {
                s += line.cross_size;
            }
            break :blk s;
        };
        container_size.set_cross(dir, node_size.cross(dir).or_else_f32(total_cross_size + padding_border.cross(dir)));
        inner_container_size.set_cross(dir, container_size.cross(dir) - padding_border.cross(dir));

        // We have the container size. If our caller does not care about performing
        // layout we are done now.

        if (!perform_layout) {
            var result = ComputeResult{ .size = container_size };
            self.nodes.items[node].layout_cache = Cache{
                .node_size = node_size,
                .parent_size = parent_size,
                .perform_layout = perform_layout,
                .result = result.clone(),
            };
            return result;
        }
        // 16. Align all flex lines per align-content.

        const free_space = inner_container_size.cross(dir) - total_cross_size;
        const num_lines = flex_lines.items.len;
        const node_align_content = self.nodes.items[node].style.align_content;

        var index_dir: isize = 1;
        var start_index: isize = 0;
        if (is_wrap_reverse and num_lines > 0) {
            index_dir = -1;
            start_index = @intCast(isize, num_lines - 1);
        }
        var line_index = start_index;
        while (line_index >= 0 and line_index < num_lines) : (line_index += index_dir) {
            const is_first = line_index == start_index;
            var line = &flex_lines.items[@intCast(usize, line_index)];
            line.offset_cross = switch (node_align_content) {
                .FlexStart => if (is_first and is_wrap_reverse) free_space else 0.0,
                .FlexEnd => if (is_first and !is_wrap_reverse) free_space else 0.0,
                .Center => if (is_first) free_space / 2.0 else 0.0,
                .SpaceBetween => if (is_first) 0.0 else free_space / @intToFloat(f32, num_lines - 1),
                .SpaceAround => if (is_first) (free_space / @intToFloat(f32, num_lines)) / 2.0 else free_space / @intToFloat(f32, num_lines),
                .Stretch => 0.0,
            };
        }

        // Do a final layout pass and gather the resulting layouts

        {
            var total_offset_cross = padding_border.cross_start(dir);
            var line_index_dir: isize = 1;
            var line_start_index: isize = 0;
            if (is_wrap_reverse and num_lines > 0) {
                line_index_dir = -1;
                line_start_index = @intCast(isize, num_lines - 1);
            }
            line_index = line_start_index;
            while (line_index >= 0 and line_index < num_lines) : (line_index += line_index_dir) {
                var line = &flex_lines.items[@intCast(usize, line_index)];
                var total_offset_main = padding_border.main_start(dir);
                const line_offset_cross = line.offset_cross;

                var child_index_dir: isize = 1;
                var child_start_index: isize = 0;
                const child_count = line.items.len;
                if (dir.is_reverse() and child_count > 0) {
                    child_index_dir = -1;
                    child_start_index = @intCast(isize, child_count - 1);
                }
                var child_index = child_start_index;
                while (child_index >= 0 and child_index < child_count) : (child_index += child_index_dir) {
                    var child = &line.items[@intCast(usize, child_index)];
                    // zig fmt: off
                    const child_result = try self.compute_internal(
                        child.node, 
                        Size(Number){
                            .width = Number.from(child.target_size.width),
                            .height = Number.from(child.target_size.height),
                        },
                        Size(Number){ 
                            .width = Number.from(container_size.width),
                            .height = Number.from(container_size.height)
                        }, 
                        true
                    );
                    const offset_main = total_offset_main
                        + child.offset_main
                        + child.margin.main_start(dir)
                        + (child.position.main_start(dir).or_else_f32(0.0) - child.position.main_end(dir).or_else_f32(0.0));
                    const offset_cross = total_offset_cross
                        + child.offset_cross
                        + line_offset_cross
                        + child.margin.cross_start(dir)
                        + (child.position.cross_start(dir).or_else_f32(0.0) - child.position.cross_end(dir).or_else_f32(0.0));

                    const order = for(self.children.items[node].items) | n, idx | {
                        if (n == child.node) {
                            break idx;
                        }
                    } else { unreachable; };

                    self.nodes.items[child.node].layout = Layout {
                        .order = @truncate(u32, order),
                        .size = child_result.size,
                        .location = Point(f32) {
                            .x = if (is_row) offset_main else offset_cross,
                            .y = if (is_column) offset_main else offset_cross,
                        }
                    };
                    // zig fmt: on
                    total_offset_main += child.offset_main + child.margin.main(dir) + child_result.size.main(dir);
                }
                total_offset_cross += line_offset_cross + line.cross_size;
            }
        }

        // Before returning we perform absolute layout on all absolutely positioned children
        {
            var order: u32 = 0;
            for (self.children.items[node].items) |child| {
                const child_style = &self.nodes.items[child].style;
                if (child_style.position_type != PositionType.Absolute) {
                    continue;
                }
                const container_width = Number.from(container_size.width);
                const container_height = Number.from(container_size.height);
                const start = child_style.position.start.resolve(container_width).add(child_style.margin.start.resolve(container_width));
                const end = child_style.position.end.resolve(container_width).add(child_style.margin.end.resolve(container_width));
                const top = child_style.position.top.resolve(container_height).add(child_style.margin.top.resolve(container_height));
                const bottom = child_style.position.bottom.resolve(container_height).add(child_style.margin.bottom.resolve(container_height));

                var start_main = top;
                var end_main = bottom;
                var start_cross = start;
                var end_cross = end;
                if (is_row) {
                    start_main = start;
                    end_main = end;
                    start_cross = top;
                    end_cross = bottom;
                }
                const fallback_width = if (start.is_defined() and end.is_defined()) container_width.sub(start).sub(end) else Number.default();
                // zig fmt: off
                const width = child_style.size
                    .width
                    .resolve(container_width)
                    .maybe_max(child_style.min_size.width.resolve(container_width))
                    .maybe_min(child_style.max_size.width.resolve(container_width))
                    .or_else(fallback_width);
                const fallback_height = if (top.is_defined() and bottom.is_defined()) container_height.sub(top).sub(bottom) else Number.default();
                const height = child_style.size
                    .height
                    .resolve(container_height)
                    .maybe_max(child_style.min_size.height.resolve(container_height))
                    .maybe_min(child_style.max_size.height.resolve(container_height))
                    .or_else(fallback_height);

                const result = try self.compute_internal(
                    child,
                    Size(Number) {
                        .width = width,
                        .height = height
                    },
                    Size(Number) {
                        .width = container_width,
                        .height = container_height
                    },
                    true
                );
                const free_main_space = container_size.main(dir) -  maybe_min_f32_number(
                    maybe_max_f32_number(
                        result.size.main(dir),
                        child_style.min_main_size(dir).resolve(node_inner_size.main(dir))
                    ),
                    child_style.max_main_size(dir).resolve(node_inner_size.main(dir))
                );

                const free_cross_space = container_size.cross(dir) - maybe_max_f32_number(
                    maybe_max_f32_number(
                        result.size.cross(dir),
                        child_style.min_cross_size(dir).resolve(node_inner_size.cross(dir))
                    ),
                    child_style.max_cross_size(dir).resolve(node_inner_size.cross(dir))
                );
                
                var offset_main: f32 = 0.0;

                if (start_main.is_defined()) {
                    offset_main = start_main.or_else_f32(0.0) + border.main_start(dir);
                } else if (end_main.is_defined()) {
                    offset_main = free_main_space - end_main.or_else_f32(0.0) - border.main_end(dir);
                } else {
                    offset_main = switch(self.nodes.items[node].style.justify_content) {
                        .SpaceBetween, .FlexStart => padding_border.main_start(dir),
                        .FlexEnd => free_main_space - padding_border.main_end(dir),
                        .SpaceEvenly, .SpaceAround, .Center => free_main_space / 2.0
                    };
                }

                var offset_cross: f32 = 0.0;
                if (start_cross.is_defined()) {
                    offset_cross = start_cross.or_else_f32(0.0) + border.cross_start(dir);
                } else if (end_cross.is_defined()) {
                    offset_cross = free_cross_space - end_cross.or_else_f32(0.0) - border.cross_end(dir);
                } else {
                    offset_cross = switch(child_style.align_self_fn(&self.nodes.items[node].style)) {
                        .Auto => 0.0,
                        .FlexStart => if (is_wrap_reverse) free_cross_space - padding_border.cross_end(dir) else padding_border.cross_start(dir),
                        .FlexEnd => if (is_wrap_reverse) padding_border.cross_start(dir) else free_cross_space - padding_border.cross_end(dir),
                        .Center => free_cross_space / 2.0,
                        .Baseline => free_cross_space / 2.0, // Treat as center for now until we have a baseline support
                        .Stretch => if (is_wrap_reverse) free_cross_space - padding_border.cross_end(dir) else padding_border.cross_start(dir),
                    };
                }
                self.nodes.items[child].layout = Layout {
                    .order = order,
                    .size = result.size,
                    .location = Point(f32) {
                        .x = if (is_row) offset_main else offset_cross,
                        .y = if (is_column) offset_main else offset_cross
                    }
                };
                // zig fmt: on
                order += 1;
            }
        }
        for(self.children.items[node].items) | child, index | {
            if (self.nodes.items[child].style.display == Display.None) {
                hidden_layout(self.nodes.items, self.children.items, child, @truncate(u32, index));
            }
        }
        var result = ComputeResult { .size = container_size };
        self.nodes.items[node].layout_cache = Cache {
            .node_size = node_size,
            .parent_size = parent_size,
            .perform_layout = perform_layout,
            .result = result.clone()
        };
        return result;
    }

    fn calc_baseline(forest: *Forest, node: NodeId, layout: *Layout) f32 {
        if (forest.children.items[node].items.len == 0) {
            return layout.size.height;
        } else {
            const child = forest.children.items[node].items[0];
            return calc_baseline(forest, child, &forest.nodes.items[child].layout);
        }
    }

    fn hidden_layout(nodes: []NodeData, children:[]ChildrenVec(NodeId), node: NodeId, order: u32) void {
        nodes[node].layout = Layout {
            .order = order,
            .size = ZeroSize(),
            .location = ZeroPoint(),
        };
        for(children[node].items) | child, idx | {
            hidden_layout(nodes, children, child, @truncate(u32, idx));
        }
    }

    fn round_layout(nodes: []NodeData, children: []ChildrenVec(NodeId), root: NodeId, abs_x: f32, abs_y: f32) void {
        var layout = &nodes[root].layout;
        const x_abs = abs_x + layout.location.x;
        const y_abs = abs_y + layout.location.y;
        layout.location.x = @round(layout.location.x);
        layout.location.y = @round(layout.location.y);
        layout.size.width = @round(x_abs + layout.size.width) - @round(x_abs);
        layout.size.height = @round(y_abs + layout.size.height) - @round(y_abs);
        for(children[root].items) | child | {
            round_layout(nodes, children, child, x_abs, y_abs);
        }
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
        //std.debug.print("  Basic\n.", .{});
        //var forest = try Forest.with_capacity(std.testing.allocator, 4);
        //defer forest.deinit();
        //const leaf_node = try forest.new_leaf(Style.default(), MeasureFunc{ .Raw = echoMeasureFunc });
        //var child_vec = try ChildrenVec(NodeId).initCapacity(std.testing.allocator, 1);
        //child_vec.appendAssumeCapacity(leaf_node);
        //_ = try forest.new_node(Style.default(), child_vec);
        //_ = Size(Number){ .width = Number{ .Defined = 100.0 }, .height = Number{ .Defined = 100.0 } };

        //forest.compute_layout(root_node, parent_size) catch {};
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

//#region node

const MeasureFunction = fn (Size(Number)) Size(f32);

pub const MeasureFunc = union(enum) { Raw: MeasureFunction, Boxed: *MeasureFunction };

var INSTANCE_ALLOCATOR: IdAllocator = IdAllocator.new();

pub const Node = struct { instance: Id, local: Id };

pub const Error = error{InvalidNode};

pub const Stretch = struct {
    const Self = @This();

    allocator: Allocator,
    id: Id,
    nodes: IdAllocator,
    nodes_to_ids: Map(Node, NodeId),
    ids_to_nodes: Map(NodeId, Node),
    forest: Forest,

    fn default(allocator: Allocator) !Self {
        return try Self.with_capacity(allocator, @as(u32, 16));
    }

    pub fn new(allocator: Allocator) !Self {
        return try Self.default(allocator);
    }

    fn new_nodes_to_id_map_with_capacity(allocator: Allocator, capacity: u32) Allocator.Error!Map(Node, NodeId) {
        var m = Map(Node, NodeId).init(allocator);
        try m.ensureTotalCapacity(capacity);
        return m;
    }

    fn new_ids_to_nodes_map_with_capacity(allocator: Allocator, capacity: u32) Allocator.Error!Map(NodeId, Node) {
        var m = Map(NodeId, Node).init(allocator);
        try m.ensureTotalCapacity(capacity);
        return m;
    }

    pub fn with_capacity(allocator: Allocator, capacity: u32) Allocator.Error!Self {
        return Self{ .id = INSTANCE_ALLOCATOR.allocate(), .nodes = IdAllocator.new(), .nodes_to_ids = try new_nodes_to_id_map_with_capacity(allocator, capacity), .ids_to_nodes = try new_ids_to_nodes_map_with_capacity(allocator, capacity), .forest = try Forest.with_capacity(allocator, capacity), .allocator = allocator };
    }

    fn allocate_node(self: *Self) Node {
        return Node{
            .instance = self.id,
            .local = self.nodes.allocate(),
        };
    }

    fn add_node(self: *Self, node: Node, id: NodeId) !void {
        _ = try self.nodes_to_ids.put(node, id);
        _ = try self.ids_to_nodes.put(id, node);
    }

    pub fn new_leaf(self: *Self, leaf_style: Style, measure: MeasureFunc) !Node {
        const node = self.allocate_node();
        const id = try self.forest.new_leaf(leaf_style, measure);
        try self.add_node(node, id);
        return node;
    }

    fn find_node(self: *Self, node: Node) !NodeId {
        if (self.nodes_to_ids.get(node)) |id| {
            return id;
        } else {
            return Error.InvalidNode;
        }
    }

    pub fn new_node(self: *Self, node_style: Style, children_nodes: []Node) !Node {
        const node = self.allocate_node();
        var children_vec = ChildrenVec(NodeId).init(self.allocator);
        for (children_nodes) |*child| {
            const node_id = try self.find_node(child.*);
            try children_vec.append(node_id);
        }
        const id = try self.forest.new_node(node_style, children_vec);
        try self.add_node(node, id);
        return node;
    }

    /// Removes all nodes.
    ///
    /// All associated nodes will be invalid.
    pub fn clear(self: *Self) void {
        self.nodes_to_ids.clearAndFree();
        self.ids_to_nodes.clearAndFree();
        self.forest.clear();
    }

    /// Remove nodes.
    pub fn remove(self: *Self, node: Node) void {
        const id = self.find_node(node) catch return;
        _ = self.nodes_to_ids.removeByPtr(&node);
        _ = self.ids_to_nodes.removeByPtr(&id);
        if (self.forest.swap_remove(id)) |new_id| {
            const brand_new_node = self.ids_to_nodes.fetchRemove(new_id).?;
            self.nodes_to_ids.put(brand_new_node, id);
            self.ids_to_nodes.put(id, brand_new_node);
        }
        self.forest.swap_remove(id);
    }

    pub fn set_measure(self: *Self, node: Node, measure: ?MeasureFunc) !void {
        const id = try self.find_node(node);
        self.forest.nodes.items[id].measure = measure;
        self.forest.mark_dirty(id);
    }

    pub fn add_child(self: *Self, node: Node, child: Node) !void {
        const node_id = try self.find_node(node);
        const child_id = try self.find_node(child);
        try self.forest.add_child(node_id, child_id);
    }

    pub fn set_children(self: *Self, node: Node, children_nodes: []Node) !void {
        const node_id = try self.find_node(node);
        var children_id = ChildrenVec(NodeId).init(self.allocator);
        for (children_nodes) |*child| {
            const id = try self.find_node(child.*);
            try children_id.append(id);
        }
        // Remove node as parent from all its current children.
        for (self.forest.children.items[node_id].items) |*child| {
            try self.forest.parents.items[child.*].append(node_id);
        }
        self.forest.children.items[node_id] = children_id;
        self.forest.mark_dirty(node_id);
    }

    pub fn remove_child(self: *Self, node: Node, child: Node) !Node {
        const node_id = try self.find_node(node);
        const child_id = try self.find_node(child);
        const prev_id = try self.forest.remove_child(node_id, child_id);
        return self.ids_to_nodes.get(prev_id).?;
    }

    pub fn remove_child_at_index(self: *Self, node: Node, index: usize) !Node {
        const node_id = try self.find_node(node);
        const prev_id = try self.forest.remove_child_at_index(node_id, index);
        return self.ids_to_nodes.get(prev_id).?;
    }

    pub fn replace_child_at_index(self: *Self, node: Node, index: usize, child: Node) !Node {
        const node_id = try self.find_node(node);
        const child_id = try self.find_node(child);
        try self.forest.parents.items[child_id].append(node_id);
        const old_child = self.forest.children.items[node_id].items[index];
        self.forest.children.items[node_id].items[index] = child_id;
        try self.forest.remove_parent_of_node(old_child, node_id);
        self.forest.mark_dirty(node_id);
        return self.ids_to_nodes.get(old_child).?;
    }

    pub fn children(self: *Self, node: Node) !Vec(Node) {
        const id = try self.find_node(node);
        const child_nodes = Vec(Node).init(self.allocator);
        for (self.forest.children.items[id].items) |*child| {
            try child_nodes.append(self.ids_to_nodes.get(child.*).?);
        }
        return child_nodes;
    }

    pub fn child_at_index(self: *Self, node: Node, index: usize) !Node {
        const id = try self.find_node(node);
        return self.ids_to_nodes.get(self.forest.children.items[id].items[index]).?;
    }

    pub fn child_count(self: *Self, node: Node) !usize {
        const id = try self.find_node(node);
        return self.forest.children.items[id].items.len;
    }

    pub fn set_style(self: *Self, node: Node, styl: Style) !void {
        const id = try self.find_node(node);
        self.forest.nodes.items[id].style = styl;
        self.forest.mark_dirty(id);
    }

    pub fn style(self: *Self, node: Node) !*Style {
        const id = try self.find_node(node);
        return &self.forest.nodes.items[id].style;
    }

    pub fn layout(self: *Self, node: Node) !*Layout {
        const id = try self.find_node(node);
        return &self.forest.nodes.items[id].layout;
    }

    pub fn mark_dirty(self: *Self, node: Node) !void {
        const id = try self.find_node(node);
        self.forest.mark_dirty(id);
    }

    pub fn dir(self: *Self, node: Node) !bool {
        const id = try self.find_node(node);
        return self.forest.nodes.items[id].is_dirty;
    }

    pub fn compute_layout(self: *Self, node: Node, size: Size(Number)) !void {
        const id = try self.find_node(node);
        try self.forest.compute_layout(id, size);
    }

    pub fn deinit(self: *Self) void {
        self.forest.deinit();
        self.nodes_to_ids.deinit();
        self.ids_to_nodes.deinit();
        INSTANCE_ALLOCATOR.free(&[_]Id{self.id});
    }
};

//#endregion node

//#region tests/measure

fn testMeasureFn_Width_100_Height_100(s: Size(Number)) Size(f32) {
    return Size(f32){ .width = s.width.or_else_f32(100.0), .height = s.height.or_else_f32(100.0) };
}

fn testMeasureFn_Width_10_Height_50(s: Size(Number)) Size(f32) {
    return Size(f32){ .width = s.width.or_else_f32(10.0), .height = s.height.or_else_f32(50.0) };
}

fn testMeasureFn_Width_100_Height_50(s: Size(Number)) Size(f32) {
    return Size(f32){ .width = s.width.or_else_f32(100.0), .height = s.height.or_else_f32(50.0) };
}

fn testMeasureFn_Width_50_Height_50(s: Size(Number)) Size(f32) {
    return Size(f32){ .width = s.width.or_else_f32(50.0), .height = s.height.or_else_f32(50.0) };
}

fn testMeasureFn_Ignore_Constraint_Width_200_Height_200(_: Size(Number)) Size(f32) {
    return Size(f32){ .width = 200.0, .height = 200.0 };
}

fn testMeasureFn_Width_10_Height_Double_Width(s: Size(Number)) Size(f32) {
    const w = s.width.or_else_f32(10.0);
    return Size(f32){ .width = w, .height = s.height.or_else_f32(w * 2.0) };
}

fn testMeasureFn_Width_100_Height_Double_Width(s: Size(Number)) Size(f32) {
    const w = s.width.or_else_f32(100.0);
    return Size(f32){ .width = w, .height = s.height.or_else_f32(w * 2.0) };
}

fn testMeasureFn_Height_50_Width_Equals_Height(s: Size(Number)) Size(f32) {
    const h = s.height.or_else_f32(50.0);
    return Size(f32){ .width = s.width.or_else_f32(h), .height = h };
}

test "measure_root" {
    std.debug.print("\n Measure Root\n", .{});
    var stretch = try Stretch.new(std.testing.allocator);
    const node = try stretch.new_leaf(Style.default(), MeasureFunc{ .Raw = testMeasureFn_Width_100_Height_100 });
    try stretch.compute_layout(node, UndefinedSize());
    const layout = try stretch.layout(node);
    std.debug.print("layout = {} \n", .{layout});
    try std.testing.expect(layout.size.width == 100.0);
    try std.testing.expect(layout.size.height == 100.0);
    defer stretch.deinit();
}

test "measure_child" {
    std.debug.print("\n  measure child\n", .{});
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();
    const child = try stretch.new_leaf(Style.default(), MeasureFunc{ .Raw = testMeasureFn_Width_100_Height_100 });
    const node = try stretch.new_node(Style.default(), &[_]Node{child});
    try stretch.compute_layout(node, UndefinedSize());
    const node_layout = stretch.layout(node) catch unreachable;
    try std.testing.expect(node_layout.size.width == 100.0);
    try std.testing.expect(node_layout.size.height == 100.0);
    const child_layout = stretch.layout(child) catch unreachable;
    try std.testing.expect(child_layout.size.width == 100.0);
    try std.testing.expect(child_layout.size.height == 100.0);
}

test "measure_child_constraint" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();
    const child = try stretch.new_leaf(Style.default(), MeasureFunc { .Raw = testMeasureFn_Width_100_Height_100 });
    var node_style = Style.default();
    node_style.size.width = Dimension { .Points = 50.0 };
    const node = try stretch.new_node(node_style, &[_]Node {child});
    try stretch.compute_layout(node, UndefinedSize());
    const node_layout = try stretch.layout(node);
    const child_layout = try stretch.layout(child);
    try std.testing.expect(node_layout.size.width == 50.0);
    try std.testing.expect(node_layout.size.height == 100.0);
    try std.testing.expect(child_layout.size.width == 50.0);
    try std.testing.expect(child_layout.size.height == 100.0);
}

test "measure_child_constraint_padding_parent" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();
    const child = try stretch.new_leaf(Style.default(), MeasureFunc { .Raw = testMeasureFn_Width_100_Height_100 });
    var node_style = Style.default();
    node_style.size.width = Dimension { .Points = 50.0 };
    const padding = Dimension { .Points = 10.0 };
    node_style.padding.start = padding;
    node_style.padding.end = padding;
    node_style.padding.top = padding;
    node_style.padding.bottom = padding;
    const node = try stretch.new_node(node_style, &[_]Node {child});
    try stretch.compute_layout(node, UndefinedSize());
    const node_layout = try stretch.layout(node);
    const child_layout = try stretch.layout(child);
    try std.testing.expect(node_layout.size.width == 50.0);
    try std.testing.expect(node_layout.size.height == 120.0);
    try std.testing.expect(child_layout.size.width == 30.0);
    try std.testing.expect(child_layout.size.height == 100.0);
}

test "measure_child_with_flex_grow" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();
    const dim_50_points = Dimension { .Points = 50.0 };
    const dim_100_points = Dimension { .Points = 100.0 };
    var child0_style = Style.default();
    child0_style.size.width = dim_50_points;
    child0_style.size.height = dim_50_points;
    const child0 = try stretch.new_node(child0_style, &[_]Node {});
    var child1_style = Style.default();
    child1_style.flex_grow = 1.0;
    const child1 = try stretch.new_leaf(child1_style, MeasureFunc { .Raw = testMeasureFn_Width_10_Height_50 });
    var node_style = Style.default();
    node_style.size.width = dim_100_points;
    const node = try stretch.new_node(node_style, &[_]Node { child0, child1 });

    try stretch.compute_layout(node, UndefinedSize());
    const child1_layout = try stretch.layout(child1);
    try std.testing.expect(child1_layout.size.width == 50.0);
    try std.testing.expect(child1_layout.size.height == 50.0);

}

test "measure_child_with_flex_shrink" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    const dim_50_points = Dimension { .Points = 50.0 };
    const dim_100_points = Dimension { .Points = 100.0 };

    var child0_style = Style.default();
    child0_style.size.width = dim_50_points;
    child0_style.size.height = dim_50_points;
    child0_style.flex_shrink = 0.0;
    const child0 = try stretch.new_node(child0_style, &[_]Node {});

    const child1_style = Style.default();
    const child1 = try stretch.new_leaf(child1_style, MeasureFunc { .Raw = testMeasureFn_Width_100_Height_50 });

    var node_style = Style.default();
    node_style.size.width = dim_100_points;
    const node = try stretch.new_node(node_style, &[_]Node { child0, child1 });

    try stretch.compute_layout(node, UndefinedSize());

    const child1_layout = try stretch.layout(child1);

    try std.testing.expect(child1_layout.size.width == 50.0);
    try std.testing.expect(child1_layout.size.height == 50.0);
}

test "remeasure_child_after_growing" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    const dim_50_points = Dimension { .Points = 50.0 };
    const dim_100_points = Dimension { .Points = 100.0 };

    var child0_style = Style.default();
    child0_style.size.width = dim_50_points;
    child0_style.size.height = dim_50_points;
    const child0 = try stretch.new_node(child0_style, &[_]Node {});


    var child1_style = Style.default();
    child1_style.flex_grow = 1.0;
    const child1 = try stretch.new_leaf(child1_style, MeasureFunc { .Raw = testMeasureFn_Width_10_Height_Double_Width });

    var node_style = Style.default();
    node_style.size.width = dim_100_points;
    node_style.align_items = AlignItems.FlexStart;
    const node = try stretch.new_node(node_style, &[_]Node { child0, child1 });

    try stretch.compute_layout(node, UndefinedSize());

    const child1_layout = try stretch.layout(child1);
    try std.testing.expect(child1_layout.size.width == 50.0);
    try std.testing.expect(child1_layout.size.height == 100.0);
}

test "remeasure_child_after_shrinking" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    const dim_50_points = Dimension { .Points = 50.0 };
    const dim_100_points = Dimension { .Points = 100.0 };

    var child0_style = Style.default();
    child0_style.size.width = dim_50_points;
    child0_style.size.height = dim_50_points;
    child0_style.flex_shrink = 0.0;
    const child0 = try stretch.new_node(child0_style, &[_]Node {});


    var child1_style = Style.default();
    const child1 = try stretch.new_leaf(child1_style, MeasureFunc { .Raw = testMeasureFn_Width_100_Height_Double_Width });

    var node_style = Style.default();
    node_style.size.width = dim_100_points;
    node_style.align_items = AlignItems.FlexStart;
    const node = try stretch.new_node(node_style, &[_]Node { child0, child1 });

    try stretch.compute_layout(node, UndefinedSize());

    const child1_layout = try stretch.layout(child1);
    try std.testing.expect(child1_layout.size.width == 50.0);
    try std.testing.expect(child1_layout.size.height == 100.0);
   
}

test "remeasure_child_after_stretching" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    const dim_100_points = Dimension { .Points = 100.0 };
    
    var child_style = Style.default();
    const child = try stretch.new_leaf(child_style, MeasureFunc { .Raw = testMeasureFn_Height_50_Width_Equals_Height });

    var node_style = Style.default();
    node_style.size.width = dim_100_points;
    node_style.size.height = dim_100_points;
    const node = try stretch.new_node(node_style, &[_]Node { child });
    
    try stretch.compute_layout(node, UndefinedSize());

    const child_layout = try stretch.layout(child);
    try std.testing.expect(child_layout.size.width == 100.0);
    try std.testing.expect(child_layout.size.height == 100.0);
}

test "width_overrides_measure" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var child_style = Style.default();
    child_style.size.width = Dimension { .Points = 50.0 };
    const child = try stretch.new_leaf(child_style, MeasureFunc { .Raw = testMeasureFn_Width_100_Height_100 });

    var node_style = Style.default();
    const node = try stretch.new_node(node_style, &[_]Node { child });

    try stretch.compute_layout(node, UndefinedSize());

    const child_layout = try stretch.layout(child);
    try std.testing.expect(child_layout.size.width == 50.0);
    try std.testing.expect(child_layout.size.height == 100.0);
}

test "height_overrides_measure" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var child_style = Style.default();
    child_style.size.height = Dimension { .Points = 50.0 };
    const child = try stretch.new_leaf(child_style, MeasureFunc { .Raw = testMeasureFn_Width_100_Height_100 });

    var node_style = Style.default();
    const node = try stretch.new_node(node_style, &[_]Node { child });

    try stretch.compute_layout(node, UndefinedSize());

    const child_layout = try stretch.layout(child);
    try std.testing.expect(child_layout.size.width == 100.0);
    try std.testing.expect(child_layout.size.height == 50.0);
}

test "flex_basis_overrides_measure" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var child0_style = Style.default();
    child0_style.flex_basis = Dimension { .Points = 50.0 };
    child0_style.flex_grow = 1.0;
    const child0 = try stretch.new_node(child0_style, &[_]Node {});

    var child1_style = Style.default();
    child1_style.flex_basis = Dimension { .Points = 50.0 };
    child1_style.flex_grow = 1.0;
    const child1 = try stretch.new_leaf(child1_style, MeasureFunc { .Raw = testMeasureFn_Width_100_Height_100 });

    var node_style = Style.default();
    node_style.size.width = Dimension { .Points = 200.0 };
    node_style.size.height = Dimension { .Points = 100.0 };
    const node = try stretch.new_node(node_style, &[_]Node { child0, child1 });

    try stretch.compute_layout(node, UndefinedSize());

    const child0_layout = try stretch.layout(child0);
    const child1_layout = try stretch.layout(child1);

    try std.testing.expect(child0_layout.size.width == 100.0);
    try std.testing.expect(child0_layout.size.height == 100.0);
    try std.testing.expect(child1_layout.size.width == 100.0);
    try std.testing.expect(child1_layout.size.height == 100.0);
}

test "stretch_overrides_measure" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var child_style = Style.default();
    const child = try stretch.new_leaf(child_style, MeasureFunc { .Raw = testMeasureFn_Width_50_Height_50 });

    var node_style = Style.default();
    node_style.size.width = Dimension { .Points = 100.0 };
    node_style.size.height = Dimension { .Points = 100.0 };
    const node = try stretch.new_node(node_style, &[_]Node { child });

    try stretch.compute_layout(node, UndefinedSize());

    const child_layout = try stretch.layout(child);
    try std.testing.expect(child_layout.size.width == 50.0);
    try std.testing.expect(child_layout.size.height == 100.0);
}

test "measure_absolute_child" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var child_style = Style.default();
    child_style.position_type = PositionType.Absolute;
    const child = try stretch.new_leaf(child_style, MeasureFunc { .Raw = testMeasureFn_Width_50_Height_50 });

    var node_style = Style.default();
    node_style.size.width = Dimension { .Points = 100.0 };
    node_style.size.height = Dimension { .Points = 100.0 };
    const node = try stretch.new_node(node_style, &[_]Node { child });

    try stretch.compute_layout(node, UndefinedSize());

    const child_layout = try stretch.layout(child);
    try std.testing.expect(child_layout.size.width == 50.0);
    try std.testing.expect(child_layout.size.height == 50.0);
}

test "ignore_invalid_measure" {
    var stretch = try Stretch.new(std.testing.allocator);
    defer stretch.deinit();

    var child_style = Style.default();
    child_style.flex_grow = 1.0;
    const child = try stretch.new_leaf(child_style, MeasureFunc { .Raw = testMeasureFn_Ignore_Constraint_Width_200_Height_200 });

    var node_style = Style.default();
    node_style.size.width = Dimension { .Points = 100.0 };
    node_style.size.height = Dimension { .Points = 100.0 };
    const node = try stretch.new_node(node_style, &[_]Node { child });

    try stretch.compute_layout(node, UndefinedSize());

    const child_layout = try stretch.layout(child);
    try std.testing.expect(child_layout.size.width == 100.0);
    try std.testing.expect(child_layout.size.height == 100.0);
}

//#endregion
