import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Minus, Plus, Search, Trash2 } from "lucide-react";
import { catalogApi } from "@/api/crmApi";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { formatCurrency } from "@/utils/format";

export default function BookPicker({ items, onChange, maxQty = 10 }) {
  const [seriesId, setSeriesId] = useState("");
  const [classLevelId, setClassLevelId] = useState("");
  const [search, setSearch] = useState("");
  const meta = useQuery({ queryKey: ["catalog-meta"], queryFn: catalogApi.seriesClassLevels });
  const titles = useQuery({ queryKey: ["catalog-titles", seriesId, classLevelId], queryFn: () => catalogApi.titles({ seriesId: seriesId || undefined, classLevelId: classLevelId || undefined }) });
  const visible = useMemo(() => (titles.data?.titles || []).filter((b) => !search || `${b.title} ${b.isbn}`.toLowerCase().includes(search.toLowerCase())), [titles.data, search]);
  const add = (book) => { if (items.some((i) => Number(i.bookId) === Number(book.book_id))) return; onChange([...items, { bookId: book.book_id, title: book.title, isbn: book.isbn, seriesId: book.series_id, subjectId: book.subject_id, classLevelId: book.class_level_id, requestedQty: 1, unitPrice: Number(book.list_price || 0), physicalStock: book.physical_stock }]); };
  const update = (bookId, qty) => onChange(items.map((i) => Number(i.bookId) === Number(bookId) ? { ...i, requestedQty: Math.max(1, Math.min(maxQty, Number(qty) || 1)) } : i));
  const remove = (bookId) => onChange(items.filter((i) => Number(i.bookId) !== Number(bookId)));

  return <div className="space-y-4">
    <div className="grid gap-3 md:grid-cols-3"><Select value={seriesId} onChange={(e) => setSeriesId(e.target.value)}><option value="">All series</option>{(meta.data?.series || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select><Select value={classLevelId} onChange={(e) => setClassLevelId(e.target.value)}><option value="">All class levels</option>{(meta.data?.classLevels || []).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</Select><div className="relative"><Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"/><Input className="pl-9" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Title / ISBN"/></div></div>
    <div className="max-h-64 overflow-y-auto rounded-xl border border-slate-200 dark:border-slate-800">{visible.length ? visible.map((b) => <button type="button" key={b.book_id} className="flex w-full items-center justify-between border-b border-slate-100 px-4 py-3 text-left last:border-0 hover:bg-slate-50 dark:border-slate-800 dark:hover:bg-slate-800" onClick={() => add(b)}><div><p className="text-sm font-semibold">{b.title}</p><p className="text-xs text-slate-500">{b.isbn || "No ISBN"} · Stock {b.physical_stock ?? "—"}</p></div><div className="flex items-center gap-2"><span className="text-sm font-semibold">{formatCurrency(b.list_price)}</span><Plus size={16}/></div></button>) : <p className="p-6 text-center text-sm text-slate-500">No books found for these filters.</p>}</div>
    {items.length > 0 && <div className="space-y-2"><p className="text-sm font-bold">Selected Books <Badge tone="blue">{items.length}</Badge></p>{items.map((i) => <div key={i.bookId} className="flex flex-wrap items-center gap-3 rounded-xl bg-slate-50 p-3 dark:bg-slate-800"><div className="min-w-0 flex-1"><p className="truncate text-sm font-semibold">{i.title}</p><p className="text-xs text-slate-500">{i.isbn || ""} · {formatCurrency(i.unitPrice)}</p></div><div className="flex items-center rounded-lg border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"><button type="button" className="p-2" onClick={() => update(i.bookId, i.requestedQty - 1)}><Minus size={14}/></button><input className="w-12 bg-transparent text-center text-sm font-semibold outline-none" type="number" min="1" max={maxQty} value={i.requestedQty} onChange={(e) => update(i.bookId, e.target.value)}/><button type="button" className="p-2" onClick={() => update(i.bookId, i.requestedQty + 1)}><Plus size={14}/></button></div><span className="w-24 text-right text-sm font-bold">{formatCurrency(i.unitPrice * i.requestedQty)}</span><Button type="button" variant="ghost" size="icon" className="text-red-600" onClick={() => remove(i.bookId)}><Trash2 size={16}/></Button></div>)}</div>}
  </div>;
}
