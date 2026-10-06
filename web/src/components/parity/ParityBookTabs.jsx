import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { BookOpen, Minus, Plus, Search, Trash2 } from "lucide-react";
import { catalogApi } from "@/api/crmApi";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { EmptyMessage } from "@/components/parity/WorkflowSection";
import { formatCurrency } from "@/utils/format";

function asBook(book) {
  return {
    bookId: Number(book.book_id),
    title: String(book.title || ""),
    isbn: String(book.isbn || ""),
    seriesId: book.series_id == null ? null : Number(book.series_id),
    seriesName: String(book.series_name || ""),
    subjectId: book.subject_id == null ? null : Number(book.subject_id),
    classLevelId: book.class_level_id == null ? null : Number(book.class_level_id),
    requestedQty: 1,
    unitPrice: Number(book.list_price ?? book.price ?? 0),
    physicalStock: book.physical_stock,
    raw: book,
  };
}

export default function ParityBookTabs({ items = [], onChange, maxQty = 10, requireSubject = false }) {
  const [tab, setTab] = useState("series");
  const [seriesId, setSeriesId] = useState("");
  const [classLevelId, setClassLevelId] = useState("");
  const [seriesSearch, setSeriesSearch] = useState("");
  const [freeText, setFreeText] = useState("");
  const [committedSearch, setCommittedSearch] = useState("");

  const meta = useQuery({ queryKey: ["catalog-meta", "flutter-parity"], queryFn: catalogApi.seriesClassLevels });
  const seriesTitles = useQuery({
    queryKey: ["catalog-titles", "flutter-parity", seriesId, classLevelId],
    queryFn: async () => {
      const exact = await catalogApi.titles({ seriesId, classLevelId: classLevelId || undefined });
      // Same compatibility behavior as the repaired Flutter app: if old catalog
      // class mapping is incomplete, retry by Series so valid books do not disappear.
      if (classLevelId && !(exact?.titles || []).length) return catalogApi.titles({ seriesId });
      return exact;
    },
    enabled: tab === "series" && Boolean(seriesId),
  });
  const freeTitles = useQuery({
    queryKey: ["catalog-title-search", committedSearch],
    queryFn: () => catalogApi.searchTitles(committedSearch),
    enabled: tab === "free" && committedSearch.trim().length >= 2,
  });

  const visibleSeries = useMemo(() => {
    const q = seriesSearch.trim().toLowerCase();
    const rows = seriesTitles.data?.titles || [];
    return q ? rows.filter((b) => `${b.title || ""} ${b.isbn || ""} ${b.author || ""}`.toLowerCase().includes(q)) : rows;
  }, [seriesTitles.data, seriesSearch]);

  function add(book) {
    const mapped = asBook(book);
    if (!mapped.bookId) return;
    if (items.some((x) => Number(x.bookId) === mapped.bookId)) return;
    onChange([...items, mapped]);
  }

  function updateQty(bookId, next) {
    const qty = Math.max(1, Math.min(Number(maxQty) || 999, Number(next) || 1));
    onChange(items.map((x) => Number(x.bookId) === Number(bookId) ? { ...x, requestedQty: qty } : x));
  }

  function remove(bookId) {
    onChange(items.filter((x) => Number(x.bookId) !== Number(bookId)));
  }

  const resultRows = tab === "series" ? visibleSeries : (freeTitles.data?.titles || []);
  const loading = tab === "series" ? seriesTitles.isFetching : freeTitles.isFetching;

  return <div className="space-y-4">
    <div className="grid grid-cols-2 overflow-hidden rounded-xl border border-white/[.08] bg-white/[.012]">
      <button type="button" onClick={() => setTab("series")} className={`px-4 py-3 text-sm font-bold ${tab === "series" ? "bg-brand-600 text-white" : "bg-transparent text-slate-500 hover:bg-white/[.03] hover:text-slate-200"}`}>Title in Series</button>
      <button type="button" onClick={() => setTab("free")} className={`px-4 py-3 text-sm font-bold ${tab === "free" ? "bg-brand-600 text-white" : "bg-transparent text-slate-500 hover:bg-white/[.03] hover:text-slate-200"}`}>Title not in Series</button>
    </div>

    {tab === "series" ? <div className="space-y-3">
      <div className="grid gap-3 md:grid-cols-3">
        <Select value={seriesId} onChange={(e) => { setSeriesId(e.target.value); setClassLevelId(""); }}>
          <option value="">--Select Series--</option>
          {(meta.data?.series || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}
        </Select>
        <Select value={classLevelId} onChange={(e) => setClassLevelId(e.target.value)} disabled={!seriesId}>
          <option value="">All Class Levels</option>
          {(meta.data?.classLevels || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}
        </Select>
        <div className="relative"><Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"/><Input className="pl-9" value={seriesSearch} onChange={(e) => setSeriesSearch(e.target.value)} placeholder="Filter title / ISBN" disabled={!seriesId}/></div>
      </div>
      {!seriesId ? <EmptyMessage>Select a Series to load available titles.</EmptyMessage> : <BookResults rows={resultRows} loading={loading} add={add}/>} 
    </div> : <div className="space-y-3">
      <div className="flex gap-2">
        <Input value={freeText} onChange={(e) => setFreeText(e.target.value)} onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); setCommittedSearch(freeText.trim()); } }} placeholder="Enter Book Title or ISBN"/>
        <Button type="button" variant="primary" onClick={() => setCommittedSearch(freeText.trim())} disabled={freeText.trim().length < 2}><Search size={16}/>Search</Button>
      </div>
      {!committedSearch ? <EmptyMessage>Enter at least 2 characters to search titles not by series.</EmptyMessage> : <BookResults rows={resultRows} loading={loading} add={add}/>} 
    </div>}

    {items.length > 0 && <div className="space-y-2 border-t border-slate-200 pt-4 dark:border-slate-800">
      <div className="flex items-center gap-2 text-sm font-bold">Selected Books <Badge tone="blue">{items.length}</Badge></div>
      {items.map((item, index) => <div key={item.bookId} className={`grid gap-3 rounded-lg border p-3 sm:grid-cols-[42px_minmax(0,1fr)_auto_auto] sm:items-center ${requireSubject && !item.subjectId ? "border-red-300 bg-red-50 dark:border-red-900 dark:bg-red-950/20" : "border-slate-200 bg-slate-50 dark:border-slate-800 dark:bg-slate-950"}`}>
        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-amber-100 text-sm font-bold text-amber-900 dark:bg-amber-900/40 dark:text-amber-200">{index + 1}</div>
        <div className="min-w-0"><p className="font-semibold">{item.title}</p><p className="mt-1 text-xs text-slate-500">{item.seriesName || "No series"}{item.isbn ? ` · ISBN ${item.isbn}` : ""}{requireSubject ? ` · Subject ID ${item.subjectId || "missing"}` : ""}</p><p className="mt-1 text-xs text-slate-500">MRP {formatCurrency(item.unitPrice)} · Stock {item.physicalStock ?? "—"}</p></div>
        <div className="flex items-center rounded-lg border border-slate-300 bg-white dark:border-slate-700 dark:bg-slate-900"><button type="button" className="p-2" onClick={() => updateQty(item.bookId, Number(item.requestedQty) - 1)}><Minus size={14}/></button><input aria-label={`Quantity for ${item.title}`} className="w-14 bg-transparent text-center text-sm font-bold outline-none" type="number" min="1" max={maxQty} value={item.requestedQty} onChange={(e) => updateQty(item.bookId, e.target.value)}/><button type="button" className="p-2" onClick={() => updateQty(item.bookId, Number(item.requestedQty) + 1)}><Plus size={14}/></button></div>
        <Button type="button" size="icon" variant="ghost" className="text-red-600" onClick={() => remove(item.bookId)}><Trash2 size={16}/></Button>
      </div>)}
    </div>}
  </div>;
}

function BookResults({ rows, loading, add }) {
  if (loading) return <div className="py-8 text-center text-sm text-slate-500">Loading books…</div>;
  if (!rows.length) return <EmptyMessage>No books found.</EmptyMessage>;
  return <div className="max-h-72 overflow-y-auto rounded-lg border border-slate-200 dark:border-slate-800">
    {rows.map((book) => <button type="button" key={book.book_id} className="flex w-full items-center justify-between gap-4 border-b border-slate-100 px-4 py-3 text-left last:border-0 hover:bg-amber-50 dark:border-slate-800 dark:hover:bg-slate-800" onClick={() => add(book)}>
      <div className="flex min-w-0 items-start gap-3"><BookOpen size={18} className="mt-0.5 shrink-0 text-amber-600"/><div className="min-w-0"><p className="font-semibold">{book.title}</p><p className="text-xs text-slate-500">{book.series_name || "No series"}{book.isbn ? ` · ${book.isbn}` : ""} · Subject {book.subject_id ?? "—"}</p></div></div>
      <div className="shrink-0 text-right"><p className="text-sm font-bold">{formatCurrency(book.list_price ?? book.price ?? 0)}</p><p className="text-xs text-slate-500">Stock {book.physical_stock ?? "—"}</p></div>
    </button>)}
  </div>;
}
