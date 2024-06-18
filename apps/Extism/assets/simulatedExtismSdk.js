// This is a simulated Extism SDK written in JavaScript in order to assist
// in the debugging of the MoonBit Extism PDK.

// Adapted from: https://dmitripavlutin.com/timeout-fetch-request/
export const fetchWithTimeout = async (resource, options = {}) => {
  const { timeout = 8000 } = options  // 8000 ms = 8 seconds

  const controller = new AbortController()
  const id = setTimeout(() => controller.abort(), timeout)
  const response = await fetch(resource, {
    ...options,
    signal: controller.signal,
  })
  clearTimeout(id)
  return response
}

// `log` and `flust` are useful for debugging the wasm-gc or wasm targets with `println()`:
export const [log, flush] = (() => {
  var buffer = []
  function flush() {
    if (buffer.length > 0) {
      console.log(new TextDecoder("utf-16").decode(new Uint16Array(buffer).valueOf()))
      buffer = []
    }
  }
  function log(ch) {
    if (ch == '\n'.charCodeAt(0)) { flush() }
    else if (ch == '\r'.charCodeAt(0)) { /* noop */ }
    else { buffer.push(ch) }
  }
  return [log, flush]
})()

const memory = new WebAssembly.Memory({ initial: 1, maximum: 1, shared: false })
const fakeAlloc = { offset: 0, buffers: {} }
const alloc = (lengthBigInt) => {
  const offset = fakeAlloc.offset
  const length = Number(lengthBigInt)
  fakeAlloc.buffers[offset] = {
    offset,
    length,
    buffer: new Uint8Array(memory.buffer, offset, length),
  }
  fakeAlloc.offset += length
  return BigInt(offset)
}
const allocAndCopy = (str) => {
  const offsetBigInt = alloc(BigInt(str.length))
  const offset = Number(offsetBigInt)
  const b = fakeAlloc.buffers[offset]
  for (let i = 0; i < str.length; i++) { b.buffer[i] = str.charCodeAt(i) }
  return offsetBigInt
}
const decodeOffset = (offset) => new TextDecoder().decode(fakeAlloc.buffers[offset].buffer)
const lastHttpResponse = { statusCode: 0 }
const http_request = async (reqOffsetBigInt, bodyOffsetBigInt) => {
  const req = JSON.parse(decodeOffset(reqOffsetBigInt))
  const body = bodyOffsetBigInt ? decodeOffset(bodyOffsetBigInt) : ''
  console.log(`http_request: req=${JSON.stringify(req)}`)
  console.log(`http_request: body=${body}`)
  const fetchParams = {
    method: req.method,
    headers: req.header,
  }
  if (body) { fetchParams.body = body }
  const response = await fetchWithTimeout(req.url, fetchParams)
  const result = await response.text()
  console.log(`result=${result}`)
  lastHttpResponse.statusCode = response.status
  return allocAndCopy(result)
}
const http_status_code = () => lastHttpResponse.statusCode

export const configs = {}  // no configs to start with
export const vars = {}  // no vars to start with

export const inputString = { value: '' }  // allows for exporting

export const importObject = {
  "extism:host/env": {
    alloc,
    config_get: (offsetBigInt) => {
      const offset = Number(offsetBigInt)
      const key = decodeOffset(offset)
      // console.log(`config_get(${offset}) = configs[${key}] = ${configs[key]}`)
      if (!configs[key]) { return BigInt(0) }
      return allocAndCopy(configs[key])
    },
    free: () => { }, // noop for now.
    http_request,
    http_status_code,
    input_length: () => BigInt(inputString.value.length),
    input_load_u8: (offsetBigInt) => {
      const offset = Number(offsetBigInt)
      if (offset < inputString.value.length) { return inputString.value.charCodeAt(offset) }
      console.error(`input_load_u8: wasm requested offset(${offset}) > inputString.value.length(${inputString.value.length})`)
      return 0
    },
    length: (offsetBigInt) => {
      const offset = Number(offsetBigInt)
      const b = fakeAlloc.buffers[offset]
      if (!b) { return BigInt(0) }
      // console.log(`length(${offset}) = ${b.length}`)
      return BigInt(b.length)
    },
    load_u8: (offsetBigInt) => {
      const offset = Number(offsetBigInt)
      const bs = Object.keys(fakeAlloc.buffers).filter((key) => {
        const b = fakeAlloc.buffers[key]
        return (offset >= b.offset && offset < b.offset + b.length)
      })
      if (bs.length !== 1) {
        console.error(`load_u8: offset ${offset} not found`)
        return 0
      }
      const key = bs[0]
      const b = fakeAlloc.buffers[key]
      const byte = b.buffer[offset - key]
      // console.log(`load_u8(${offset}) = ${byte}`)
      return byte
    },
    log_info: (offset) => console.info(`log_info: ${decodeOffset(offset)}`),
    log_debug: (offset) => console.log(`log_debug: ${decodeOffset(offset)}`),
    log_error: (offset) => console.error(`log_error: ${decodeOffset(offset)}`),
    log_warn: (offset) => console.warn(`log_warn: ${decodeOffset(offset)}`),
    output_set: (offset) => console.log(decodeOffset(offset)),
    store_u8: (offsetBigInt, byte) => {
      const offset = Number(offsetBigInt)
      Object.keys(fakeAlloc.buffers).forEach((key) => {
        const b = fakeAlloc.buffers[key]
        if (offset >= b.offset && offset < b.offset + b.length) {
          b.buffer[offset - key] = byte
          // console.log(`store_u8(${offset})=${byte}`)
          // if (offset == b.offset + b.length - 1) {
          //   console.log(`store_u8 completed offset=${key}..${offset}, length=${b.length}: '${decodeOffset(key)}'`)
          // }
        }
      })
    },
    var_get: (offsetBigInt) => {
      const offset = Number(offsetBigInt)
      const key = decodeOffset(offset)
      // console.log(`var_get(${offset}) = vars[${key}] = ${vars[key]}`)
      if (!vars[key]) { return BigInt(0) }
      return vars[key]  // BigInt
    },
    var_set: (offsetBigInt, bufOffsetBigInt) => {
      const offset = Number(offsetBigInt)
      const key = decodeOffset(offset)
      // console.log(`var_set(${offset}, ${bufOffsetBigInt}) = vars[${key}]`)
      vars[key] = bufOffsetBigInt
    },
  },
  spectest: { print_char: log },
}
