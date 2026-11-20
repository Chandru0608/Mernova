import { useEffect, useState } from "react";
import api from "./api";

export default function App() {
  const [token, setToken] = useState(localStorage.getItem("qd_token"));
  const [email, setEmail] = useState("admin@quickdeliver.test");
  const [password, setPassword] = useState("Admin123!");
  const [user, setUser] = useState(null);
  const [tab, setTab] = useState("overview");
  const [stores, setStores] = useState([]);
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);
  const [error, setError] = useState("");
  const [product, setProduct] = useState({ name:"", price:"", store:"", type:"grocery", category:"general", stock:"10" });

  async function load() {
    const [me, st, pr, ord] = await Promise.all([
      api.get("/auth/me"), api.get("/stores/my-stores"), api.get("/products"), api.get("/orders/store")
    ]);
    setUser(me.data.user); setStores(st.data.stores); setProducts(pr.data.products); setOrders(ord.data.orders);
    if (!product.store && st.data.stores[0]) setProduct(p => ({...p, store: st.data.stores[0]._id}));
  }
  useEffect(() => { if (token) load().catch(e => setError(e.response?.data?.message || "Could not load dashboard")); }, [token]);

  async function login(e) {
    e.preventDefault(); setError("");
    try {
      const r = await api.post("/auth/login", { email, password });
      localStorage.setItem("qd_token", r.data.token); setToken(r.data.token);
    } catch (e) { setError(e.response?.data?.message || "Login failed"); }
  }
  function logout() { localStorage.removeItem("qd_token"); setToken(null); setUser(null); }
  async function addProduct(e) {
    e.preventDefault();
    try { await api.post("/products", {...product, price:Number(product.price), stock:Number(product.stock)}); setProduct(p=>({...p,name:"",price:""})); await load(); }
    catch(e) { setError(e.response?.data?.message || "Could not add product"); }
  }
  async function updateStatus(id, status) {
    try { await api.patch(`/orders/${id}/status`, {status}); await load(); }
    catch(e) { setError(e.response?.data?.message || "Could not update order"); }
  }

  if (!token) return <main className="login"><form className="panel" onSubmit={login}><div className="brand">🛵 QuickDeliver</div><h1>Dashboard sign in</h1><label>Email<input value={email} onChange={e=>setEmail(e.target.value)} type="email"/></label><label>Password<input value={password} onChange={e=>setPassword(e.target.value)} type="password"/></label>{error&&<p className="error">{error}</p>}<button>Sign in</button><small>Seed admin: admin@quickdeliver.test / Admin123!</small></form></main>;

  return <div className="shell"><aside><div className="brand">🛵 QuickDeliver</div><p>{user?.name}</p><nav>{["overview","products","orders","stores"].map(x=><button className={tab===x?"active":""} onClick={()=>setTab(x)} key={x}>{x[0].toUpperCase()+x.slice(1)}</button>)}</nav><button className="secondary" onClick={logout}>Log out</button></aside><main className="content"><header><div><h1>{tab[0].toUpperCase()+tab.slice(1)}</h1><p>Food and grocery delivery operations</p></div><span className="pill">{user?.role}</span></header>{error&&<p className="error">{error}</p>}
    {tab==="overview"&&<><section className="stats"><article><b>{stores.length}</b><span>Stores</span></article><article><b>{products.length}</b><span>Products</span></article><article><b>{orders.length}</b><span>Orders</span></article></section><h2>Recent orders</h2><OrderList orders={orders.slice(0,6)} updateStatus={updateStatus}/></>}
    {tab==="products"&&<><form className="panel product-form" onSubmit={addProduct}><h2>Add product</h2><input placeholder="Product name" value={product.name} onChange={e=>setProduct({...product,name:e.target.value})} required/><input placeholder="Price" type="number" min="0" value={product.price} onChange={e=>setProduct({...product,price:e.target.value})} required/><select value={product.store} onChange={e=>setProduct({...product,store:e.target.value})}>{stores.map(s=><option value={s._id} key={s._id}>{s.name}</option>)}</select><select value={product.type} onChange={e=>setProduct({...product,type:e.target.value})}><option value="grocery">Grocery</option><option value="food">Food</option></select><input placeholder="Category" value={product.category} onChange={e=>setProduct({...product,category:e.target.value})}/><input type="number" min="0" placeholder="Stock" value={product.stock} onChange={e=>setProduct({...product,stock:e.target.value})}/><button>Add product</button></form><h2>Products</h2><div className="grid">{products.map(p=><article className="panel" key={p._id}><b>{p.name}</b><p>₹{p.price} · {p.type} · Stock {p.stock}</p><small>{p.store?.name}</small></article>)}</div></>}
    {tab==="orders"&&<OrderList orders={orders} updateStatus={updateStatus}/>}
    {tab==="stores"&&<div className="grid">{stores.map(s=><article className="panel" key={s._id}><b>{s.name}</b><p>{s.type} · {s.address}</p><small>Owner: {s.owner?.name || "—"}</small></article>)}</div>}
  </main></div>;
}
function OrderList({orders,updateStatus}) {
  if(!orders.length) return <p>No orders yet.</p>;
  return <div className="stack">{orders.map(o=><article className="panel order" key={o._id}><div><b>Order #{o._id.slice(-6)}</b><p>{o.customer?.name || "Customer"} · {o.store?.name || "Store"}</p><small>{o.items?.map(i=>`${i.name} × ${i.quantity}`).join(", ")}</small><p><b>₹{o.total}</b> · <span className="pill">{o.status}</span></p></div><select value={o.status} onChange={e=>updateStatus(o._id,e.target.value)}><option value="accepted">Accepted</option><option value="preparing">Preparing</option><option value="ready">Ready</option><option value="delivered">Delivered</option><option value="cancelled">Cancelled</option></select></article>)}</div>;
}
