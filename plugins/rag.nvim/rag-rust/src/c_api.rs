use crate::index::RagEngine;
use crate::models::Config;
use std::ffi::CStr;
use std::os::raw::c_char;
use std::ptr;
use std::sync::Arc;
use std::sync::Mutex;

#[repr(C)]
pub struct SearchResult {
    pub file_path: *mut c_char,
    pub id: i64,
    pub chunk_text: *mut c_char,
    pub line_no: i32,
    pub distance: f64,
}

#[repr(C)]
pub struct RagEnginePtr {
    engine: *mut RagEngine,
}

static mut ENGINES: std::sync::Mutex<std::collections::HashMap<u64, RagEngine>> = 
    std::sync::Mutex::new(std::collections::HashMap::new());

static mut ENGINE_COUNTER: u64 = 0;

fn cstr_to_string<'a>(c_str: &'a CStr) -> String {
    c_str.to_string_lossy().into_owned()
}

fn string_to_cstr(s: &str) -> *mut c_char {
    let c_str = std::ffi::CString::new(s).expect("CString::new failed");
    c_str.into_raw()
}

#[no_mangle]
pub extern "C" fn rag_engine_new(config_json: *const c_char) -> *mut RagEnginePtr {
    if config_json.is_null() {
        return ptr::null_mut();
    }
    
    let c_str = unsafe { CStr::from_ptr(config_json) };
    let config_str = cstr_to_string(c_str);
    
    match serde_json::from_str::<Config>(&config_str) {
        Ok(config) => {
            let engine = match RagEngine::new(Some(serde_json::to_value(config).unwrap())) {
                Ok(e) => e,
                Err(_) => return ptr::null_mut(),
            };
            
            let mut engines = unsafe { ENGINES.lock().unwrap() };
            let id = unsafe { ENGINE_COUNTER };
            unsafe { ENGINE_COUNTER += 1 };
            
            engines.insert(id, engine);
            
            let mut ptr = RagEnginePtr { engine: ptr::null_mut() };
            ptr.engine = Box::into_raw(Box::new(engine));
            
            Box::into_raw(Box::new(ptr))
        }
        Err(_) => ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn rag_engine_index_file(engine_ptr: *mut RagEnginePtr, file_path: *const c_char) -> bool {
    if engine_ptr.is_null() || file_path.is_null() {
        return false;
    }
    
    unsafe {
        let engine = &mut *engine_ptr;
        let c_str = CStr::from_ptr(file_path);
        let file_path_str = cstr_to_string(c_str);
        
        match engine.engine.as_mut().unwrap().index_file(&file_path_str, None) {
            Ok(_) => true,
            Err(_) => false,
        }
    }
}

#[no_mangle]
pub extern "C" fn rag_engine_reindex(engine_ptr: *mut RagEnginePtr) -> bool {
    if engine_ptr.is_null() {
        return false;
    }
    
    unsafe {
        match engine_ptr.engine.as_mut().unwrap().reindex() {
            Ok(_) => true,
            Err(_) => false,
        }
    }
}

#[no_mangle]
pub extern "C" fn rag_engine_search(
    engine_ptr: *mut RagEnginePtr,
    query: *const c_char,
    limit: usize,
) -> *mut SearchResult {
    if engine_ptr.is_null() || query.is_null() {
        return ptr::null_mut();
    }
    
    unsafe {
        let engine = &mut *engine_ptr;
        let c_str = CStr::from_ptr(query);
        let query_str = cstr_to_string(c_str);
        
        match engine.engine.as_mut().unwrap().search(&query_str, limit) {
            Ok(results) => {
                let result_vec = results.into_iter().collect::<Vec<_>>();
                
                let mut result_ptrs = Vec::with_capacity(limit);
                
                for result in result_vec.iter().take(limit) {
                    let file_path_ptr = string_to_cstr(&result.file_path);
                    let chunk_text_ptr = string_to_cstr(&result.chunk_text);
                    
                    result_ptrs.push(SearchResult {
                        file_path: file_path_ptr,
                        id: result.id,
                        chunk_text: chunk_text_ptr,
                        line_no: result.line_no,
                        distance: result.distance,
                    });
                }
                
                let ptr = Box::into_raw(Box::new(result_ptrs));
                ptr as *mut SearchResult
            }
            Err(_) => ptr::null_mut(),
        }
    }
}

#[no_mangle]
pub extern "C" fn rag_engine_update_on_write(
    engine_ptr: *mut RagEnginePtr,
    file_path: *const c_char,
) -> bool {
    if engine_ptr.is_null() || file_path.is_null() {
        return false;
    }
    
    unsafe {
        let engine = &mut *engine_ptr;
        let c_str = CStr::from_ptr(file_path);
        let file_path_str = cstr_to_string(c_str);
        
        match engine.engine.as_mut().unwrap().update_on_write(&file_path_str) {
            Ok(_) => true,
            Err(_) => false,
        }
    }
}

#[no_mangle]
pub extern "C" fn rag_engine_free(engine_ptr: *mut RagEnginePtr) {
    if !engine_ptr.is_null() {
        unsafe {
            let engine = Box::from_raw(engine_ptr);
            engine.close();
        }
    }
}