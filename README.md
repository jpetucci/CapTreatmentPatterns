Community acquired penumonia treatment patterns study
=============

<img src="https://img.shields.io/badge/Study%20Status-Design%20Finalized-brightgreen.svg" alt="Study Status: Design Finalized">

- Analytics use case(s): **Characterization**
- Study type: **Clinical Application**
- Tags: **TreatmentPatterns**
- Study lead: **Anna Ostropolets**
- Study lead forums tag: **[[aostropolets]](https://forums.ohdsi.org/u/aostropolets)**
- Study start date: **01/01/2025**
- Study end date: **-**
- Protocol: **docs/GDE2025 CAP Treatment Pathways Protocol.docx**
- Publications: **-**
- Results explorer: **-**

This study focuses on exploring the patterns of antibiotics therapy in patients with community-acquired pneumonia across the network. We will explore sequences of drugs prescribed to such patients as well in a subgroup of hospitalized patients.

Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, Google BigQuery, or Microsoft APS.
- R version 4.0.5
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 100 GB of free disk space

How to run
==========
1. Follow [these instructions](https://ohdsi.github.io/Hades/rSetup.html) for setting up your R environment, including RTools and Java.

2. Open your study package in RStudio. Use the following code to install all the dependencies:

	```r
	install.packages("renv")
	renv::activate()
	renv::restore()
	```

3. Open StrategusCodeToRun.R, change database connection parameters to your database connection (Lines starting with START OF INPUTS and endind with END OF INPUTS) abnd execute the file.

4. Share outputs located in results folder with the study lead

