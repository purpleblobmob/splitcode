#!/bin/bash

### Setup ###

splitcode="./src/splitcode"
test_dir="./func_tests"

cmdexec() {
	cmd="$1"
	expect_fail="$2"
	printf "$cmd\n"
	if eval "$cmd 2> /dev/null 1> /dev/null"; then
		if [ "$expect_fail" = "1" ]; then
			printf "^[Failed - Returned normally but expected failure]\n"
			exit 1
		else
			printf "^[OK]\n"
		fi
	else
		if [ "$expect_fail" = "1" ]; then
			printf "^[OK - Exited non-zero as expected]\n"
		else
			printf "^[Failed]\n"
			exit 1
		fi
	fi
}

checkcmdoutput() {
	cmd="$1"
	correct_md5="$2"
	printf "$cmd\n"
	output_md5=$(eval "$cmd"|md5sum|awk '{ print $1 }')
	if [ "$output_md5" = "$correct_md5" ]; then
		printf "^[Output OK]\n"
	else
		printf "^[Output incorrect! Expected: "
		printf "$correct_md5"
		printf " Actual: "
		printf "$output_md5"
		printf "]\n"
		exit 1
	fi	
}

# Test that program can be run

cmdexec "$splitcode --version"

# Test SPRITE config files

cmdexec "$splitcode -t 1 -o "$test_dir/A_out_1.fastq.gz,$test_dir/A_out_2.fastq.gz" -O $test_dir/A_out_barcodes.fastq.gz -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --mod-names --gzip -m $test_dir/A_out_mapping.txt.gz $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz"
checkcmdoutput "zcat < $test_dir/A_out_1.fastq.gz" 05eb0a03078777fb36ec0a463707b1c6
checkcmdoutput "zcat < $test_dir/A_out_2.fastq.gz" 6780951145cb17370b8977aad4513355
checkcmdoutput "zcat < $test_dir/A_out_barcodes.fastq.gz" 395253488fa5a04acdb42af9291e1139
checkcmdoutput "zcat < $test_dir/A_out_mapping.txt.gz" 3bed011f0405480768019a0f2ceb445e
checkcmdoutput "$splitcode -t 1 --pipe -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --mod-names -m /dev/null $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz" a9857b5416fa815d63f3b262252f5f4f
checkcmdoutput "$splitcode -t 1 --pipe -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --com-names -m /dev/null $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz" d9bd0b3183cfb50256d5473af2f6476e
checkcmdoutput "$splitcode -t 1 -y <(echo "Y,ODD,EVEN,LIGTAG") -N 2 -c $test_dir/splitcode_example_config_2.txt --mod-names --com-names --pipe -m /dev/null $test_dir/B_1.fastq.gz $test_dir/B_2.fastq.gz" af7415d5cae5cd87ec9c38faeb0a3093
checkcmdoutput "$splitcode -t 1 -y <(echo "Y,ODD,EVEN,LIGTAG") -N 2 -c $test_dir/splitcode_example_config_3.txt --mod-names --com-names --pipe -m /dev/null $test_dir/B_1.fastq.gz $test_dir/B_2.fastq.gz" af7415d5cae5cd87ec9c38faeb0a3093

# Basic UMI extraction testing

checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") -m /dev/null --pipe -x \"{Odd2Bo50}<umi[6]>\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -16" 4a413abb788efb880a35e6d60ca4ac4d
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{Odd2Bo50}<umi[6]>\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -16" bea2940a59a5fcc833310e894a9b2c2d

# Advanced UMI extraction testing 1

checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{Odd2Bo50}<umi[6-120]>,{Odd2Bo50}<umi[10-100]>,{Odd2Bo50}<umi[6-9]>\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -16" 9c78c856d1bb693b784cf44c6acea43f
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{Odd2Bo50}<umi1[39]>,{Odd2Bo50}<umi2[40]>\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -20" 27ac575249c7338c3bf90ab1ab1f32c0
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{Odd2Bo50}<umi[41]>\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -16" 03ba76e5c5f2649a6e39d71490b81f73
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{Odd2Bo50}<umi[6]>,{Odd2Bo50}<umi[9]>,{Odd2Bo50}9<umi1[5]>,{Odd2Bo50}<umi2[9]>,{Odd2Bo50}<umi1[3]>\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -24" 5481a84873d0fc929a28ba47ed6a9f6e
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{Even2Bo33}<umi>{Odd2Bo50},{Even2Bo33}1<umi>2{Odd2Bo50},{Even2Bo33}1<umi[4-5]>2{Odd2Bo50},{Even2Bo33}1<umi[7-9]>2{Odd2Bo50},{Even2Bo33}1<umi1[5-7]>2{Odd2Bo50},{Even2Bo33}1<umi1[6]>2{Odd2Bo50},{Even2Bo33}1<umi2[6]>2{Odd2Bo50}\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -24" ef843b20cc6af4f692840692ffffe680
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{DPM6H4}1<umi0[5]>,{DPM6H4}1<umi1>{Even2Bo33},{Odd2Bo10}<umi2>{Even2Bo33},{Odd2Bo10}<umi3>{Odd2Bo50},{Odd2Bo10}2<umi4>{Even2Bo33},{Odd2Bo10}<umi4[1-2]>2{Odd2Bo50},{Odd2Bo50}<umi5[5-100]>,{Odd2Bo10}<umi4>2{Odd2Bo50}\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -36" 85e0e59877d3402f14f57dba424f96ed

# Advanced UMI extraction testing 2

checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{{ODD}}<umi>{{ODD}},{{ODD}}<umi1>{Odd2Bo50},{{ODD}}<umi2>{{EVEN}}\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -24" 4e1e5cd270efdacbe9de77b568fb03da
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{{DPM}}<umi>{{EVEN}},{{EVEN}}<umi>{{EVEN}},{{EVEN}}<umi>{Odd2Bo10}\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -16" 03ba76e5c5f2649a6e39d71490b81f73
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"{{EVEN}}<umi1>{Odd2Bo50},{{ODD}}<umi2>{{EVEN}},{{ODD}}<umi3>{{ODD}},{{EVEN}}<umi4>{{EVEN}},{{EVEN}}<umi5>{{ODD}}\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -32" c5f22e5f8d29c145a44bd95b0bbcd190

# Advanced UMI extraction testing 3

checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"0:4<umi[92]>,0:1<umi[10]>,0:1<umi1[5]>,0:3<umi2[5]>,0:4<umi3[6]>,1:1<umi4[5]>,0:5<umi5[8]>\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -36" b7f129379a232040c83a638961619644
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"<umi[10]>0:1,<umi1[10]>0:10,<umi1[10]>0:20,<umi2[20]>0:-1,<umi3[20]>1:-1\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -28" 39aae648d41c03eaa3c2ccc4948866aa
checkcmdoutput "$splitcode -t 1 -N 2 -c $test_dir/splitcode_example_config.txt -y <(echo "DPM,Y,ODD,EVEN,ODD") --x-names -m /dev/null --pipe -x \"<umi1[96]>0:-1,<umi2[10]>0:10,<umi2[10]>0:10,<umi3[20]>1:-1,<umi4[21]>1:-1\" $test_dir/A_1.fastq.gz $test_dir/A_2.fastq.gz|head -28" 466ac29defbd770b78c4a0fdf25bd5a4



