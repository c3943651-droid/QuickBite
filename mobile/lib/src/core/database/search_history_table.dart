class SearchHistoryTable extends Table {
  Id get id => Id();
  Text get term;
  Int64 get timestamp;
}