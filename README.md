# Introduction
This repo contains all the source files you need to build a TPC-H data model in Power BI using DAX. It follows the YouTube video series "From SQL to DAX" that shows you how to convert SQL queries into DAX measures.

# Data Enginnering
In this folder, you will find the source codes for data transformations using three different technologies: DuckDB, Databricks, and Power Query. You can use any of these codes to prepare your data for analysis in Power BI.

# Data Analysis
In this folder, you will find the Power BI template file (PBIT) that uses a local parquet files (created using the pervious DuckDB code) as the data source. You will also find the SQL file that has all the 22 TPC-H queries replicated in the Power BI report.

# TPC-H Documentation
For more information about the TPC-H benchmark, you can refer to [this document](https://www.tpc.org/tpc_documents_current_versions/pdf/tpc-h_v3.0.1.pdf)