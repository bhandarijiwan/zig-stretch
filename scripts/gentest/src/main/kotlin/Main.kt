import kotlin.io.path.Path
import kotlin.io.path.exists
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.absolutePathString
import java.io.File
import java.io.FileWriter
import java.nio.file.Paths
import java.util.concurrent.TimeUnit

import org.openqa.selenium.safari.SafariOptions
import org.openqa.selenium.safari.SafariDriver
import org.openqa.selenium.By

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.decodeFromString


@Serializable
data class ResolvedLayout(
	val width: Float,
	val height: Float,
	val x: Float,
	val y: Float
)

@Serializable
data class Size(
	val width: Dimension? = null,
	val height: Dimension? = null
)

@Serializable
data class Edge(
	val start: Dimension? = null,
	val end: Dimension? = null,
	val top: Dimension? = null,
	val bottom: Dimension? = null
)

@Serializable
data class DefinedStyle (
	val display: String? = null,
	val position_type: String? = null,
	val direction: String? = null,
	val flexDirection: String? = null,

	val flexWrap: String? = null,
	val overflow: String? = null,
	
	val alignItems: String? = null,
	val alignSelf: String? = null,
	val alignContent: String? = null,

	val justifyContent: String? = null,

	val flexGrow: Float? = null,
	val flexShrink: Float? = null,
	val flexBasis: Dimension? = null,

	val size: Size? = null,
	val min_size: Size? = null,
	val max_size: Size? = null,
	
	val margin: Edge? = null,
	val padding: Edge? = null,
	val border: Edge? = null,
	val position: Edge? = null,
)

@Serializable
data class Dimension (
	val unit: String,
	val value: Float?
)

@Serializable
data class Node(
	val style: DefinedStyle,
	val layout: ResolvedLayout,
	val children: List<Node>
)


fun main(args: Array<String>) {
	if (args.size < 1) {
		throw RuntimeException("fixture path is required")
	}
	if (args.size < 2) {
		throw RuntimeException("output path is required")
	}
	val fixturePath = Path(args[0])
	if (!fixturePath.exists()) {
		throw RuntimeException("fixture path '${fixturePath}' is invalid.")
	}
	val outDirPath = Path(args[1])
	if (!outDirPath.exists()) {
		throw RuntimeException("output path '$outDirPath' is invalid. ")
	}
	val fixtures = fixturePath.listDirectoryEntries("*.html")
	val options = SafariOptions()
	val driver = SafariDriver(options)
	val fixtureDesc = mutableMapOf<String, String>();
	for(fixture in fixtures) {
		val fixutureUrl = "file://" + fixture.toAbsolutePath().normalize().absolutePathString()
		driver.get(fixutureUrl)
		val testRootElement = driver.findElement(By.ById("test-root"))
		val stretchDescAttribute = testRootElement.getAttribute("__stretch_description__")
		fixtureDesc[fixutureUrl] = stretchDescAttribute;
	}
	driver.quit()
	for(entry in fixtureDesc.entries) {
		val name = File(entry.key).nameWithoutExtension
		val stretch = Json.decodeFromString<Node>(entry.value)
		val testCode = generateTest(name, stretch)
		FileWriter(Paths.get(outDirPath.toString(), "$name.zig").toFile(), false).use {
			it.write(testCode)
		}
	}
	val formatCommand = "zig fmt ${outDirPath.toString()}"
	val formatCommandParts = formatCommand.split(" ")
	ProcessBuilder(*formatCommandParts.toTypedArray())
		.redirectOutput(ProcessBuilder.Redirect.INHERIT)
		.redirectError(ProcessBuilder.Redirect.INHERIT)
		.start()
		.waitFor(60, TimeUnit.SECONDS)
}

fun generateTest(name: String, desc: Node): String {
	val nodeDescriptions = generateNodeDescription("node", desc)
	//val assertions = generateAssertions()
	
	return """
	const std = @import("std");
	const testing = std.testing;

	test "$name" {
		var stretch = try Stretch.new(std.testing.allocator);
    	defer stretch.deinit();

		$nodeDescriptions

		try stretch.compute_layout(node, UndefinedSize());
	}
	""".trimIndent();
}

fun generateNodeDescription(ident: String, node: Node): String {
	val style = node.style;
	var nodeStyleSb = StringBuilder();

	when(style.display) {
		"none" -> {
			nodeStyleSb.append("${ident}_style.display = Display.Node;\n")
		}
	}

	when(style.position_type) {
		"absolute" -> {
			nodeStyleSb.append("${ident}_style.position_type = PositionType.Absolute;\n")
		}
	}

	when(style.direction) {
		"rtl" -> nodeStyleSb.append("${ident}_style.direction = Direction.RTL;\n")
		"ltr" -> nodeStyleSb.append("${ident}_style.direction = Direction.LTR;\n")
	}

	when(style.flexDirection) {
		"row-reverse" -> nodeStyleSb.append("${ident}_style.flex_direction = FlexDirection.RowReverse;\n")
		"column" -> nodeStyleSb.append("${ident}_style.flex_direction = FlexDirection.Column;\n")
		"column-reverse" -> nodeStyleSb.append("${ident}_style.flex_direction = FlexDirection.ColumnReverse;\n")
	}

	when(style.flexWrap) {
		"wrap" -> nodeStyleSb.append("${ident}_style.flex_wrap = FlexWrap.Wrap;\n")
		"wrap-reverse" -> nodeStyleSb.append("${ident}_style.flex_wrap = FlexWrap.WrapReverse;\n")
	}

	when(style.overflow) {
		"hidden" -> nodeStyleSb.append("${ident}_style.overflow = Overflow.Hidden;\n")
		"scroll" -> nodeStyleSb.append("${ident}_style.overflow = Overflow.Scroll;\n")
    }

    when(style.alignItems) {
		"flex-start" -> nodeStyleSb.append("${ident}_style.align_items = AlignItems.FlexStart;\n")
		"flex-end" -> nodeStyleSb.append("${ident}_style.align_items = AlignItems.FlexEnd;\n")
		"center" -> nodeStyleSb.append("${ident}_style.align_items = AlignItems.Center;\n")
		"baseline" -> nodeStyleSb.append("${ident}_style.align_items = AlignItems.Baseline;\n")
	}

	when(style.alignSelf) {
    	"flex-start" -> nodeStyleSb.append("${ident}_style.align_self = AlignSelf.FlexStart;\n")
		"flex-end" -> nodeStyleSb.append("${ident}_style.align_self = AlignSelf.FlexEnd;\n")
		"center" -> nodeStyleSb.append("${ident}_style.align_self = AlignSelf.Center;\n")
		"baseline" -> nodeStyleSb.append("${ident}_style.align_self = AlignSelf.Baseline;\n")
		"stretch" -> nodeStyleSb.append("${ident}_style.align_self = AlignSelf.Stretch;\n")
	}

    when(style.alignContent) {
    	"flex-start" -> nodeStyleSb.append("${ident}_style.align_content = AlignContent.FlexStart;\n")
		"flex-end" -> nodeStyleSb.append("${ident}_style.align_content = AlignContent.FlexEnd;\n")
		"center" -> nodeStyleSb.append("${ident}_style.align_content = AlignContent.Center;\n")
		"space-between" -> nodeStyleSb.append("${ident}_style.align_content = AlignContent.SpaceBetween;\n")
		"space-around" -> nodeStyleSb.append("${ident}_style.align_content = AlignContent.SpaceAround;\n")
    }

    when(style.justifyContent) {
		"flex-end" -> nodeStyleSb.append("${ident}_style.justify_content = JustifyContent.FlexEnd;\n")
		"center" -> nodeStyleSb.append("${ident}_style.justify_content = JustifyContent.Center;\n")
		"space-between" -> nodeStyleSb.append("${ident}_style.justify_content = JustifyContent.SpaceBetween;\n")
		"space-around" -> nodeStyleSb.append("${ident}_style.justify_content = JustifyContent.SpaceAround;\n")
		"space-evenly" -> nodeStyleSb.append("${ident}_style.justify_content = JustifyContent.SpaceEvenly;\n")
    }


    when(style.flexGrow) {
        is Float -> nodeStyleSb.append("${ident}_style.flex_grow = ${style.flexGrow};\n")
    }

    when(style.flexShrink) {
        is Float -> nodeStyleSb.append("${ident}_style.flex_shrink = ${style.flexShrink};\n")
    }

    when(style.flexBasis) {
		is Dimension -> {
			generateDimension(style.flexBasis)?.let { nodeStyleSb.append("${ident}_style.flex_basis = ${it};\n") }
		}
    }

    when(style.size) {
		is Size -> {
			generateDimension(style.size.width)?.let { nodeStyleSb.append("${ident}_style.size.width = ${it};\n") }
			generateDimension(style.size.height)?.let { nodeStyleSb.append("${ident}_style.size.height = ${it};\n") }
		}
    };

    when(style.min_size) {
        is Size -> {
			generateDimension(style.min_size.width)?.let { nodeStyleSb.append("${ident}_style.min_size.width = ${it};\n") }
			generateDimension(style.min_size.height)?.let { nodeStyleSb.append("${ident}_style.min_size.height = ${it};\n") }
		}
    }

    when(style.max_size) {
        is Size -> {
			generateDimension(style.max_size.width)?.let { nodeStyleSb.append("${ident}_style.max_size.width = ${it};\n") }
			generateDimension(style.max_size.height)?.let { nodeStyleSb.append("${ident}_style.max_size.height = ${it};\n") }
		}
    }

	when(style.margin) {
		is Edge -> {
			generateDimension(style.margin.start)?.let { nodeStyleSb.append("${ident}_style.margin.start = ${it};\n") }
			generateDimension(style.margin.end)?.let { nodeStyleSb.append("${ident}_style.margin.end = ${it};\n") }
			generateDimension(style.margin.top)?.let { nodeStyleSb.append("${ident}_style.margin.top = ${it};\n") }
			generateDimension(style.margin.bottom)?.let { nodeStyleSb.append("${ident}_style.margin.bottom = ${it};\n") }
		}
	}

	when(style.padding) {
		is Edge -> {
			generateDimension(style.padding.start)?.let { nodeStyleSb.append("${ident}_style.padding.start = ${it};\n") }
			generateDimension(style.padding.end)?.let { nodeStyleSb.append("${ident}_style.padding.end = ${it};\n") }
			generateDimension(style.padding.top)?.let { nodeStyleSb.append("${ident}_style.padding.top = ${it};\n") }
			generateDimension(style.padding.bottom)?.let { nodeStyleSb.append("${ident}_style.padding.bottom = ${it};\n") }
		}
	}

	when(style.position) {
		is Edge -> {
			generateDimension(style.position.start)?.let { nodeStyleSb.append("${ident}_style.position.start = ${it};\n") }
			generateDimension(style.position.end)?.let { nodeStyleSb.append("${ident}_style.position.end = ${it};\n") }
			generateDimension(style.position.top)?.let { nodeStyleSb.append("${ident}_style.position.top = ${it};\n") }
			generateDimension(style.position.bottom)?.let { nodeStyleSb.append("${ident}_style.position.bottom = ${it};\n") }
		}
	}

	when(style.border) {
		is Edge -> {
			generateDimension(style.border.start)?.let { nodeStyleSb.append("${ident}_style.border.start = ${it};\n") } 
			generateDimension(style.border.end)?.let { nodeStyleSb.append("${ident}_style.border.end = ${it};\n") }
			generateDimension(style.border.top)?.let { nodeStyleSb.append("${ident}_style.border.top = ${it};\n") }
			generateDimension(style.border.bottom)?.let { nodeStyleSb.append("${ident}_style.border.bottom = ${it};\n") }
		}
	}

	val children = mutableListOf<String>()
	val childrenBody = mutableListOf<String>()
	for((index, childNode) in node.children.withIndex()) {
		val childIdent = "${ident}_${index+1}"
		val childBody = generateNodeDescription(childIdent, childNode)
		children.add(childIdent)
		childrenBody.add(childBody)
	}

	var childrenIdentifiersSlice = "&[_]Node"
	if (children.size > 0) {
		childrenIdentifiersSlice +=  "{ " + children.joinToString(", ") + " } "
	} else {
		childrenIdentifiersSlice += "{}"
	}
	val childrenBodyString = childrenBody.joinToString("\n");
	return """
	${childrenBodyString}
	
	var ${ident}_style = Style.default();
	${nodeStyleSb.toString()}
	const ${ident} = try stretch.new_node(
		${ident}_style,
		$childrenIdentifiersSlice
	);
	""".trimIndent();
}

fun generateDimension(d: Dimension?): String? {
	d ?: return null
	return when(d.unit) {
		"auto" -> "Dimension.Auto"
		"points" -> "Dimension { .Points = ${d.value} }"
		"percent" -> "Dimension { .Percent = ${d.value} }"
		else -> null
	}
}

