/*Combining data*/
data panel;
infile "/folders/myfolders/sasuser.v94/deod/deod_PANEL_GR_1114_1165.dat" firstobs=2 delimiter='	';
input PANID	WEEK	UNITS	OUTLET$	DOLLARS	IRI_KEY	COLUPC;
run;

data panel2;
set panel;
upc = put(colupc,z13.);
run;

PROC IMPORT DATAFILE='/folders/myfolders/sasuser.v94/deod/prod_deod.xls'
	DBMS=XLS
	replace
	OUT=WORK.IMPORT;
	GETNAMES=YES;
RUN;

data b1;
set work.import;
sy1 = sy*1; 
ge1 = ge*1;
vend1 = vend*1;
item1 = item*1;
sy2 = put(sy1,z2.);
vend2 = put(vend1,z5.);
item2 = put(item1,z5.);
key = catt(sy2,ge1,vend2,item2);run;

data brand;
set b1;
keep key l3;
run;


PROC IMPORT DATAFILE='/folders/myfolders/sasuser.v94/deod/ads demo1.csv'
	DBMS=csv
	replace
	OUT=WORK.IMPORT1;
	GETNAMES=YES;
RUN;

proc sql;
create table panel_d as 
select a.*,b.* from panel2 a left join work.import1 b on a.panid = b.Panelist_ID order by panid;run;

proc sql;
create table panel_data as
select a.*,b.l3 from panel_d a left join brand b on a.upc = b.key order by panid;run;

proc sql;
select distinct PANID from panel_data; run;

/*RFM Analsis*/

proc sql;
create table mon as
select distinct PANID,sum(Dollars) as monetory_amount,max(week) as Recency, count(1) as Frequency from panel group by PANID order by monetory_amount desc;
run;

proc print data = mon ; run;

/*proc sql;
select PANID, sum(dollars) as a from d1 group by PANID order by a desc;
run;
proc sql;
select PANID, max(week) as Recency from d1 group by PANID order by recency desc;
run;
proc sql;
select PANID,count(1) as Frequency from d1 group by PANID order by frequency desc;
run;*/

proc sql;
create table rfm as select 
PANID, 
case when Recency between 1155 and  1165 then 5
when Recency between 1145 and  1154 then 4
when Recency between 1135 and  1144 then 3
when Recency between 1125 and  1134 then 2
else 1
end as R,
case when frequency > 36 then 5
when frequency between 28 and 36 then 4
when frequency between 19 and 27 then 3
when frequency between 10 and 18 then 2
else 1
end as F, 
case when monetory_amount > 217 then 5 
when monetory_amount between 163 and 217 then 4
when monetory_amount between 109 and 162 then 3
when monetory_amount between 55 and 108 then 2
else 1 
end as M
from mon;
run;

proc sql;
create table RFM_Final as 
select PANID, R, F, M, R*100+F*10+M as RFM_Code from rfm order by RFM_Code desc;
run;

/*Comining two*/
proc sql;
create table clst as
select a.*, b.R, b.F, b.M, b.RFM_Code from panel_data a left join RFM_Final b on a.PANID = b.PANID; run;

/*based on monetory amount*/
proc sort data = clst; by M; run;

proc means data = clst;
by M;
var R F M RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year;
run;

/*based on frequency*/
proc sort data = clst; by F; run;

proc means data = clst;
by F;
var R F M RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year;
run;

/*based on recency*/

proc sort data = clst; by R; run;

proc means data = clst;
by R;
var R F M RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year;
run;

/*based on rfm code*/
proc sort data = clst; by RFM_Code; run;

proc means data = clst;
by RFM_Code;
var R F M RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year;
run;


proc tabulate data = clst out = graph1;
var RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year;
class R;
format R;
table R = ' ',
n pctn='Market Share' (RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year) * mean = ' '/box = 'Cluster';
run;

proc tabulate data = clst out = graph1;
var RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year;
class F;
format F;
table F = ' ',
n pctn='Market Share' (RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year) * mean = ' '/box = 'Cluster';
run;

proc tabulate data = clst out = graph1;
var RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year;
class M;
format M;
table M = ' ',
n pctn='Market Share' (RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year) * mean = ' '/box = 'Cluster';
run;

proc tabulate data = clst out = graph1;
var Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status Year;
class RFM_Code;
format RFM_Code;
table RFM_Code = ' ',
n pctn='Market Share' ( Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status) * mean = ' '/box = 'Cluster';
run;

proc sql;
create table FC as select 
PANID, 
case when RFM_Code in (534, 542, 545, 553) then 5
when RFM_Code in (511,514,521,522,531,532) then 4
when RFM_Code in (411,412,421,432,443) then 3
when RFM_Code in (311,312,321,331) then 2
else 1
end as cluster
from clst;
run;

proc sql;
create table clst1 as
select distinct a.*, b.cluster from clst a left join FC b on a.PANID = b.PANID; run;

proc tabulate data = clst1 out = graph1;
var RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status;
class cluster;
format cluster;
table cluster = ' ',
n pctn='Market Share' (RFM_Code Combined_Pre_Tax_Income_of_HH Family_Size HH_RACE Type_of_Residential_Possession
Age_Group_Applied_to_Male_HH Education_Level_Reached_by_Male Occupation_Code_of_Male_HH Male_Working_Hour_Code 
Age_Group_Applied_to_Female_HH Education_Level_Reached_by_Femal Occupation_Code_of_Female_HH Female_Working_Hour_Code 
Number_of_Dogs Number_of_Cats Children_Group_Code Marital_Status) * mean = ' '/box = 'Cluster';
run;
