#!/usr/bin/perl
print "\n=================VERISHORT TESTBENCH==================\n\n";

#Counters
$totalTests = 0;
$passedTests = 0;

#Get every test file into an array
@verishorts=`ls tests/*.vs`;

#For every test file, test it
foreach $verishortTestFile (@verishorts) {
	#Take out the whitespace in the filename
	chomp $verishortTestFile;
	
	#Get the translated and goal filenames
	$originalVerishortTestFile = $verishortTestFile;
	$verishortTestFile =~  s/\.vs/\.v/;
	$translatedFile = $verishortTestFile;
	$verishortTestFile =~ s/\.v/Goal\.v/;
	$goal = $verishortTestFile;
	
	#print "./printer $originalVerishortTestFile\n";
	#print `cat $originalVerishortTestFile\n`;
	#print `./printer $originalVerishortTestFile\n`;

	#Translate the verishort
	$translate = "./vsc $originalVerishortTestFile | tee $translatedFile | sed 's/_//g' | sed 's/_//g' | sed 's/_//g'";
	print "$translate\n";
	print `$translate\n`; #This line actually executes
	
	#$translate =~ s/\s//;
	#$goal =~ s/\s//;

	#Test the differences between the file.  If there are no differences, that test was passed
	$test = "diff -ie $translatedFile $goal";
	print "$test\n";
	$diffResult = `$test`;
	print "$diffResult";
	if ($diffResult =~ m/^$/) {
		print "Translated file matches goal: $originalVerishortTestFile\n";
		$passedTests++;
		}
	else {
		print "Translated file does not match goal: $originalVerishortTestFile\n";
		}
	
	
	#Test that the file compiles correctly
	#$compile = "iverilog $translated -s $translated";
	#print "$compile\n";
	#$compileResult = `$compile`;
	#print "$compileResult";
	
	
	#Remove the compiled file
	#$remove = "rm $translatedFile";
	print "$remove\n";
	print `$remove`;
	
	#Increment
	print "\n";
	$totalTests++;
	}

#Check the error checker

=comment
#Get every test file into an array
@verishorts=`ls error_tests/*.vs`;

#For every test file, test it
foreach $verishortTestFile (@verishorts) {
	#Take out the whitespace in the filename
	chomp $verishortTestFile;
	
	#Get the translated and goal filenames
	$originalVerishortTestFile = $verishortTestFile;
	$verishortTestFile =~  s/\.vs/\.v/;
	$translated = $verishortTestFile;
	$verishortTestFile =~ s/\.v/Goal\.v/;
	$goal = $verishortTestFile;
	
	print "./printer $originalVerishortTestFile\n";
	print `cat $originalVerishortTestFile\n`;
	print `./printer $originalVerishortTestFile\n`;

=comment
	#Translate the verishort
	$translate = "./vsc $originalVerishortTestFile";
	print "$translate\n";
	print `$translate\n`;

	#Test the differences between the file.  If there are no differences, that test was passed
	$test = "diff $translated $goal";
	print "$test\n";
	$diffResult = `$test`;
	print "$diffResult";
	if ($diffResult =~ m/^$/) {
		print "Translated file matches goal: $originalVerishortTestFile\n";
		$passedTests++;
		}
	else {
		print "Translated file does not match goal: $originalVerishortTestFile\n";
		}
	
	
	#Test that the file compiles correctly
	#$compile = "iverilog $translated -s $translated";
	#print "$compile\n";
	#$compileResult = `$compile`;
	#print "$compileResult";
	
	
	#Remove the compiled file\
	$remove = "rm $translated";
	print "$remove\n";
	print `$remove`;
	
	#Increment
	print "\n";
	$totalTests++;
	}

=cut

#Print final messages
print "==========================\n";
if ($passedTests == $totalTests) {
	print "PASSED ALL TESTS!\n";
	}
else {
	print "Failed atleast one test\n";
	}
print "Passed: $passedTests/$totalTests\n";
