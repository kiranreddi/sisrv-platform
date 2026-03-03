# Interfaces

## Internal core bus (corebus) — simple req/resp
Goal: keep the core independent of AXI. The core issues *one* request at a time and waits for response.

### Request channel (core -> fabric)
- `req_valid`
- `req_ready`
- `req_addr[31:0]`
- `req_we` (1=write, 0=read)
- `req_wdata[31:0]`
- `req_wstrb[3:0]`
- `req_size[1:0]` (00=byte,01=half,10=word; optional)
- `req_is_instr` (1=fetch, 0=data; optional)

### Response channel (fabric -> core)
- `rsp_valid`
- `rsp_ready`
- `rsp_rdata[31:0]`
- `rsp_err` (optional for bus errors)

### Rules
- Single outstanding transaction (MVP).
- `req_valid` held stable until `req_ready` handshake.
- `rsp_valid` asserted exactly once per request; held until `rsp_ready`.

## AXI4-Lite master (MVP profile)
Implement subset:
- Read: AR + R
- Write: AW + W + B
- No bursts (LEN not present in Lite)
- Single outstanding read and single outstanding write
- In-order responses

Signals (standard AXI-Lite):
- AW: `awvalid, awready, awaddr[31:0], awprot[2:0]`
- W : `wvalid, wready, wdata[31:0], wstrb[3:0]`
- B : `bvalid, bready, bresp[1:0]`
- AR: `arvalid, arready, araddr[31:0], arprot[2:0]`
- R : `rvalid, rready, rdata[31:0], rresp[1:0]`

### Bridge behavior
- Convert corebus req to AXI transaction.
- Insert backpressure: corebus `req_ready` only when bridge idle.
- Complete on `R` or `B` handshake.

### Error handling
- Map AXI `RESP != OKAY` to `rsp_err=1` (optional); core may trap later.
