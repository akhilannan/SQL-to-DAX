// UnzipContents
(ZIPFile) =>
let
    Header = BinaryFormat.Record([
        MiscHeader = BinaryFormat.Binary(14),
        BinarySize = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        FileSize   = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        FileNameLen= BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
        ExtrasLen  = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian)    
    ]),
 
    HeaderChoice = BinaryFormat.Choice(
        BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        each if _ <> 67324752             // not the IsValid number? then return a dummy formatter
            then BinaryFormat.Record([IsValid = false, Filename=null, Content=null])
            else BinaryFormat.Choice(
                    BinaryFormat.Binary(26),      // Header payload - 14+4+4+2+2
                    each BinaryFormat.Record([
                        IsValid  = true,
                        Filename = BinaryFormat.Text(Header(_)[FileNameLen]),
                        Extras   = BinaryFormat.Text(Header(_)[ExtrasLen]),
                        Content  = BinaryFormat.Transform(
                            BinaryFormat.Binary(Header(_)[BinarySize]),
                            (x) => try Binary.Buffer(Binary.Decompress(x, Compression.Deflate)) otherwise null
                        )
                        ]),
                        type binary                   // enable streaming
                )
    ),
 
    ZipFormat = BinaryFormat.List(HeaderChoice, each _[IsValid] = true),
 
    Entries = List.Transform(
        List.RemoveLastN( ZipFormat(ZIPFile), 1),
        (e) => [FileName = e[Filename], Content = e[Content] ]
    )
in
    Table.FromRecords(Entries)

// FileList
let
    Source = Web.Contents("https://uhesse.files.wordpress.com/2020/08/mytpch_oracle.zip"),
    UnzipFiles = UnzipContents(Source)
in
    UnzipFiles

// customerRaw
let
    Source = FileList,
    Content = Source{[FileName="customer.txt"]}[Content],
    #"Imported CSV" = Csv.Document(Content,[Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Renamed Columns" = Table.RenameColumns(#"Imported CSV",{{"Column1", "c_custkey"}, {"Column2", "c_name"}, {"Column3", "c_address"}, {"Column4", "c_nationkey"}, {"Column5", "c_phone"}, {"Column6", "c_acctbal"}, {"Column7", "c_mktsegment"}, {"Column8", "c_comment"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"c_custkey", Int64.Type}, {"c_nationkey", Int64.Type}, {"c_acctbal", Currency.Type}})
in
    #"Changed Type"

// nation
let
    Source = FileList,
    Content = Source{[FileName="nation.txt"]}[Content],
    #"Imported CSV" = Csv.Document(Content,[Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Renamed Columns" = Table.RenameColumns(#"Imported CSV",{{"Column1", "n_nationkey"}, {"Column2", "n_name"}, {"Column3", "n_regionkey"}, {"Column4", "n_comment"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"n_nationkey", Int64.Type}, {"n_regionkey", Int64.Type}})
in
    #"Changed Type"

// region
let
    Source = FileList,
    Content = Source{[FileName="region.txt"]}[Content],
    #"Imported CSV" = Csv.Document(Content,[Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Renamed Columns" = Table.RenameColumns(#"Imported CSV",{{"Column1", "r_regionkey"}, {"Column2", "r_name"}, {"Column3", "r_comment"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"r_regionkey", Int64.Type}})
in
    #"Changed Type"

// supplierRaw
let
    Source = FileList,
    Content = Source{[FileName="supplier.txt"]}[Content],
    #"Imported CSV" = Csv.Document(Content,[Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Renamed columns" = Table.RenameColumns(#"Imported CSV", {{"Column1", "s_suppkey"}, {"Column2", "s_name"}, {"Column3", "s_address"}, {"Column4", "s_nationkey"}, {"Column5", "s_phone"}, {"Column6", "s_acctbal"}, {"Column7", "s_comment"}}),
  #"Changed Type" = Table.TransformColumnTypes(#"Renamed columns", {{"s_suppkey", Int64.Type}, {"s_nationkey", Int64.Type}, {"s_acctbal", Currency.Type}})
in
    #"Changed Type"

// partRaw
let
    Source = FileList,
    Content = Source{[FileName="part.txt"]}[Content],
    #"Imported CSV" = Csv.Document(Content,[Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
  #"Renamed columns" = Table.RenameColumns(#"Imported CSV", {{"Column1", "p_partkey"}, {"Column2", "p_name"}, {"Column3", "p_mfgr"}, {"Column4", "p_brand"}, {"Column5", "p_type"}, {"Column6", "p_size"}, {"Column7", "p_container"}, {"Column8", "p_retailprice"}, {"Column9", "p_comment"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"p_retailprice", Currency.Type}, {"p_partkey", Int64.Type}, {"p_size", Int64.Type}})
in
    #"Changed column type"

// partsupp
let
    Source = FileList,
    Content = Source{[FileName="partsupp.txt"]}[Content],
    #"Imported CSV" = Csv.Document(Content,[Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
  #"Renamed columns" = Table.RenameColumns(#"Imported CSV", {{"Column1", "ps_partkey"}, {"Column2", "ps_suppkey"}, {"Column3", "ps_availqty"}, {"Column4", "ps_supplycost"}, {"Column5", "ps_comment"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"ps_partkey", Int64.Type}, {"ps_suppkey", Int64.Type}, {"ps_availqty", Int64.Type}, {"ps_supplycost", Currency.Type}})
in
    #"Changed column type"

// orders
let
    Source = FileList,
    Content = Source{[FileName="orders.txt"]}[Content],
    #"Imported CSV" = Csv.Document(Content,[Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
  #"Renamed columns" = Table.RenameColumns(#"Imported CSV", {{"Column1", "o_orderkey"}, {"Column2", "o_custkey"}, {"Column3", "o_orderstatus"}, {"Column4", "o_totalprice"}, {"Column5", "o_orderdate"}, {"Column6", "o_orderpriority"}, {"Column7", "o_clerk"}, {"Column8", "o_shippriority"}, {"Column9", "o_comment"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"o_orderkey", Int64.Type}, {"o_custkey", Int64.Type}, {"o_totalprice", Currency.Type}, {"o_orderdate", type date}, {"o_shippriority", Int64.Type}})
in
    #"Changed column type"

// lineitem
let
    Source = FileList,
    Content = Source{[FileName="lineitem.txt"]}[Content],
    #"Imported CSV" = Csv.Document(Content,[Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
  #"Renamed columns" = Table.RenameColumns(#"Imported CSV", {{"Column1", "l_orderkey"}, {"Column2", "l_partkey"}, {"Column3", "l_suppkey"}, {"Column4", "l_linenumber"}, {"Column5", "l_quantity"}, {"Column6", "l_extendedprice"}, {"Column7", "l_discount"}, {"Column8", "l_tax"}, {"Column9", "l_returnflag"}, {"Column10", "l_linestatus"}, {"Column11", "l_shipdate"}, {"Column12", "l_commitdate"}, {"Column13", "l_receiptdate"}, {"Column14", "l_shipinstruct"}, {"Column15", "l_shipmode"}, {"Column16", "l_comment"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"l_orderkey", Int64.Type}, {"l_partkey", Int64.Type}, {"l_suppkey", Int64.Type}, {"l_linenumber", Int64.Type}, {"l_quantity", Int64.Type}, {"l_extendedprice", Currency.Type}, {"l_discount", Currency.Type}, {"l_tax", Currency.Type}, {"l_shipdate", type date}, {"l_commitdate", type date}, {"l_receiptdate", type date}})
in
    #"Changed column type"

// Customer
let
    Source = customerRaw,
    #"Merged Queries" = Table.NestedJoin(Source, {"c_nationkey"}, nation, {"n_nationkey"}, "nation", JoinKind.Inner),
    #"Expanded nation" = Table.ExpandTableColumn(#"Merged Queries", "nation", {"n_name", "n_regionkey"}, {"n_name", "n_regionkey"}),
    #"Merged Queries1" = Table.NestedJoin(#"Expanded nation", {"n_regionkey"}, region, {"r_regionkey"}, "region", JoinKind.Inner),
    #"Expanded region" = Table.ExpandTableColumn(#"Merged Queries1", "region", {"r_name"}, {"r_name"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded region",{{"c_custkey", "custkey"}, {"c_name", "Customer Name"}, {"c_address", "Customer Address"}, {"c_phone", "Customer Phone No"}, {"c_acctbal", "Customer Account Balance"}, {"c_mktsegment", "Market Segment"}, {"c_comment", "Customer Comment"}, {"n_name", "Customer Nation"}, {"r_name", "Customer Region"}}),
    #"Removed Columns" = Table.RemoveColumns(#"Renamed Columns",{"c_nationkey", "n_regionkey"})
in
    #"Removed Columns"

// Supplier
let
  Source = supplierRaw,
    #"Merged Queries" = Table.NestedJoin(Source, {"s_nationkey"}, nation, {"n_nationkey"}, "nation", JoinKind.Inner),
    #"Expanded nation" = Table.ExpandTableColumn(#"Merged Queries", "nation", {"n_name", "n_regionkey"}, {"n_name", "n_regionkey"}),
    #"Merged Queries1" = Table.NestedJoin(#"Expanded nation", {"n_regionkey"}, region, {"r_regionkey"}, "region", JoinKind.Inner),
    #"Expanded region" = Table.ExpandTableColumn(#"Merged Queries1", "region", {"r_name"}, {"r_name"}),
  #"Renamed columns" = Table.RenameColumns(#"Expanded region", {{"s_name", "Supplier Name"}, {"s_address", "Supplier Address"}, {"s_phone", "Supplier Phone No"}, {"s_acctbal", "Supplier Account Balance"}, {"s_comment", "Supplier Comment"}, {"n_name", "Supplier Nation"}, {"r_name", "Supplier Region"}, {"s_suppkey", "suppkey"}}),
  #"Removed columns" = Table.RemoveColumns(#"Renamed columns", {"n_regionkey", "s_nationkey"})
in
  #"Removed columns"

// Part
let
  Source = partRaw,
  #"Renamed columns" = Table.RenameColumns(Source, {{"p_name", "Part Name"}, {"p_mfgr", "Manufacturer"}, {"p_brand", "Brand"}, {"p_type", "Type"}, {"p_size", "Size"}, {"p_container", "Container"}, {"p_partkey", "partkey"}}),
  #"Removed columns" = Table.RemoveColumns(#"Renamed columns", {"p_retailprice", "p_comment"})
in
  #"Removed columns"

// Order Info
let
  Source = orders,
  #"Merged queries" = Table.NestedJoin(Source, {"o_orderkey"}, lineitem, {"l_orderkey"}, "lineitem", JoinKind.LeftOuter),
  #"Expanded lineitem" = Table.ExpandTableColumn(#"Merged queries", "lineitem", {"l_returnflag", "l_linestatus", "l_shipinstruct", "l_shipmode"}, {"l_returnflag", "l_linestatus", "l_shipinstruct", "l_shipmode"}),
  #"Removed other columns" = Table.SelectColumns(#"Expanded lineitem", {"o_orderstatus", "o_shippriority", "l_returnflag", "l_linestatus", "l_shipinstruct", "l_shipmode", "o_orderpriority"}),
  #"Removed duplicates" = Table.Distinct(#"Removed other columns"),
  #"Added index" = Table.AddIndexColumn(#"Removed duplicates", "orderinfokey", 1, 1, Int64.Type),
  #"Renamed columns" = Table.RenameColumns(#"Added index", {{"o_orderstatus", "Order Status"}, {"o_shippriority", "Ship Priority"}, {"l_returnflag", "Return Flag"}, {"l_linestatus", "Line Status"}, {"l_shipinstruct", "Ship Instruct"}, {"l_shipmode", "Ship Mode"}, {"o_orderpriority", "Order Priority"}})
in
  #"Renamed columns"

// Stock
let
  Source = partsupp,
  #"Removed columns" = Table.RemoveColumns(Source, {"ps_comment"}),
  #"Renamed columns" = Table.RenameColumns(#"Removed columns", {{"ps_partkey", "partkey"}, {"ps_suppkey", "suppkey"}, {"ps_availqty", "availqty"}, {"ps_supplycost", "supplycost"}})
in
  #"Renamed columns"

// Sales
let
  Source = orders,
  JoinToLine = Table.NestedJoin(Source, {"o_orderkey"}, lineitem, {"l_orderkey"}, "lineitem", JoinKind.Inner),
  SelectFromLine = Table.ExpandTableColumn(JoinToLine, "lineitem", {"l_partkey", "l_suppkey", "l_quantity", "l_discount", "l_tax", "l_returnflag", "l_linestatus", "l_shipdate", "l_commitdate", "l_receiptdate", "l_shipinstruct", "l_shipmode"}, {"l_partkey", "l_suppkey", "l_quantity", "l_discount", "l_tax", "l_returnflag", "l_linestatus", "l_shipdate", "l_commitdate", "l_receiptdate", "l_shipinstruct", "l_shipmode"}),
  JoinToPartsupp = Table.NestedJoin(SelectFromLine, {"l_partkey", "l_suppkey"}, partsupp, {"ps_partkey", "ps_suppkey"}, "partsupp", JoinKind.Inner),
  SelectFromPartsupp = Table.ExpandTableColumn(JoinToPartsupp, "partsupp", {"ps_supplycost"}),
  JoinToPart = Table.NestedJoin(SelectFromPartsupp, {"l_partkey"}, partRaw, {"p_partkey"}, "partRaw", JoinKind.Inner),
  SelectFromPart = Table.ExpandTableColumn(JoinToPart, "partRaw", {"p_retailprice"}),
  JoinToOrderinfo = Table.NestedJoin(SelectFromPart, {"o_shippriority","l_shipmode", "o_orderpriority", "o_orderstatus", "l_shipinstruct", "l_returnflag", "l_linestatus"}, #"Order Info", {"Ship Priority","Ship Mode", "Order Priority", "Order Status", "Ship Instruct", "Return Flag", "Line Status"}, "Order Info", JoinKind.Inner),
  SelectFromOrderinfo = Table.ExpandTableColumn(JoinToOrderinfo, "Order Info", {"orderinfokey"}),
  SelectColumns = Table.SelectColumns(SelectFromOrderinfo, {"l_partkey", "l_suppkey", "o_custkey", "o_orderkey", "orderinfokey", "l_shipdate", "o_orderdate", "l_commitdate", "l_receiptdate", "l_quantity", "p_retailprice", "l_discount", "ps_supplycost", "l_tax", "o_comment"}),
  #"Renamed columns" = Table.RenameColumns(SelectColumns, {{"l_partkey", "partkey"}, {"l_suppkey", "suppkey"}, {"o_custkey", "custkey"}, {"o_orderkey", "orderkey"}, {"l_shipdate", "shipdate"}, {"o_orderdate", "orderdate"}, {"l_commitdate", "commitdate"}, {"l_receiptdate", "receiptdate"}, {"l_quantity", "quantity"}, {"p_retailprice", "retailprice"}, {"l_discount", "discount"}, {"ps_supplycost", "supplycost"}, {"l_tax", "tax"}, {"o_comment", "Order Comment"}})
in
  #"Renamed columns"