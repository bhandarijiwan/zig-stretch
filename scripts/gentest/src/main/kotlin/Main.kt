import kotlin.io.path.*;

import org.openqa.selenium.safari.SafariOptions
import org.openqa.selenium.safari.SafariDriver

fun main(args: Array<String>) {
	val fixturePath = Path(args[0])
	if (!fixturePath.exists()) {
		throw RuntimeException("fixture path '${fixturePath}' is invalid.")
	}
	val outDirPath = Path(args[1])
	if (!outDirPath.exists()) {
		throw RuntimeException("output path '$outDirPath' is invalid. ")
	}
	val options = SafariOptions()
	val driver = SafariDriver(options)

	driver.get("https://google.com")
	
	driver.quit()
	
}
