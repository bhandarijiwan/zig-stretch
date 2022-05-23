import kotlin.io.path.Path
import kotlin.io.path.exists
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.absolutePathString
import java.io.File


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
		println(name)
		println(stretch)
	}
}