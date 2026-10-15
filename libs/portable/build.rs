fn main() {
    #[cfg(windows)]
    {
        use std::io::Write;
        let mut res = winres::WindowsResource::new();
        #[cfg(feature = "overdesk")]
        res.set("ProductName", "OverDesk")
            .set("FileDescription", "OverDesk")
            .set("OriginalFilename", "OverDesk.exe")
            .set("CompanyName", "Over Enterprise LTDA.")
            .set("LegalCopyright", "Copyright © 2026 Over Enterprise LTDA.");
        let icon = if cfg!(feature = "overdesk") {
            "../../res/overdesk/icon.ico"
        } else {
            "../../res/icon.ico"
        };
        res.set_icon(icon)
            .set_language(winapi::um::winnt::MAKELANGID(
                winapi::um::winnt::LANG_ENGLISH,
                winapi::um::winnt::SUBLANG_ENGLISH_US,
            ))
            .set_manifest_file("../../res/manifest.xml");
        match res.compile() {
            Err(e) => {
                write!(std::io::stderr(), "{}", e).unwrap();
                std::process::exit(1);
            }
            Ok(_) => {}
        }
    }
}
