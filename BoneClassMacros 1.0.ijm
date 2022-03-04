macro "SetDotGreen [q]" {
	run("Properties... ", "  stroke=Green");
		showStatus("Developing");
}

macro "SetDotYellow [w]" {
	run("Properties... ", "  stroke=Yellow");
	showStatus("Resting");
}

macro "SetDotBlack [e]" {
	run("Properties... ", "  stroke=Black");
	showStatus("Degrading");
}

macro "SetDotGray [r]" {
	run("Properties... ", "  stroke=Gray");
	showStatus("NA");
}

macro "MeasureDots [m]"{
	Selections = getValue("selection.size");
	colour = getInfo("selection.color");
	run("Measure");
	ResultsNr = nResults;
	Startposition = ResultsNr - Selections;
	for (x = Startposition; x < ResultsNr; x++) {
		setResult("Colour", x, colour);
	}
	run("Add Selection...");
	run("Select None");
}