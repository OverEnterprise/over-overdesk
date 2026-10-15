use base::config::keys;
use hbb_common::config;

const SERVER: &str = "rustdesk.overenterprise.com.br";
const SERVER_KEY: &str = include_str!("../res/overdesk/server_key.pub");

pub fn init() {
    *config::APP_NAME.write().unwrap() = "OverDesk".to_owned();
    config::HARD_SETTINGS
        .write()
        .unwrap()
        .insert("disable-account".to_owned(), "Y".to_owned());
    config::BUILTIN_SETTINGS.write().unwrap().extend([
        (
            keys::OPTION_HIDE_NETWORK_SETTINGS.to_owned(),
            "Y".to_owned(),
        ),
        (
            keys::OPTION_HIDE_SECURITY_SETTINGS.to_owned(),
            "Y".to_owned(),
        ),
        (keys::OPTION_HIDE_SERVER_SETTINGS.to_owned(), "Y".to_owned()),
        (keys::OPTION_REGISTER_DEVICE.to_owned(), "N".to_owned()),
        (
            keys::OPTION_ENABLE_PERM_CHANGE_IN_ACCEPT_WINDOW.to_owned(),
            "N".to_owned(),
        ),
    ]);
    config::OVERWRITE_SETTINGS.write().unwrap().extend([
        (
            keys::OPTION_CUSTOM_RENDEZVOUS_SERVER.to_owned(),
            SERVER.to_owned(),
        ),
        (keys::OPTION_RELAY_SERVER.to_owned(), SERVER.to_owned()),
        (keys::OPTION_KEY.to_owned(), SERVER_KEY.trim().to_owned()),
        (keys::OPTION_API_SERVER.to_owned(), String::new()),
        (keys::OPTION_APPROVE_MODE.to_owned(), "click".to_owned()),
        (keys::OPTION_ACCESS_MODE.to_owned(), "full".to_owned()),
        (keys::OPTION_ALLOW_WEBSOCKET.to_owned(), "N".to_owned()),
        (keys::OPTION_DISABLE_UDP.to_owned(), String::new()),
        (keys::OPTION_ENABLE_TCP_PUNCH.to_owned(), "Y".to_owned()),
        (keys::OPTION_ENABLE_UDP_PUNCH.to_owned(), "N".to_owned()),
        (keys::OPTION_ENABLE_IPV6_PUNCH.to_owned(), "N".to_owned()),
        (keys::OPTION_ENABLE_WEBRTC.to_owned(), "N".to_owned()),
    ]);
    config::Config::set_socks(None);
}

#[cfg(windows)]
pub fn custom_server() -> crate::custom_server::CustomServer {
    crate::custom_server::CustomServer {
        host: SERVER.to_owned(),
        relay: SERVER.to_owned(),
        key: SERVER_KEY.trim().to_owned(),
        api: String::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn overdesk_uses_fixed_oss_server_without_accounts() {
        init();
        assert_eq!(crate::get_app_name(), "OverDesk");
        assert!(config::is_disable_account());
        assert_eq!(config::Config::get_rendezvous_servers(), vec![SERVER]);
        assert_eq!(
            config::Config::get_option(keys::OPTION_RELAY_SERVER),
            SERVER
        );
        assert_eq!(
            config::Config::get_option(keys::OPTION_KEY),
            SERVER_KEY.trim()
        );
        assert_eq!(
            config::Config::get_option(keys::OPTION_APPROVE_MODE),
            "click"
        );
        assert_eq!(
            crate::ui_interface::get_builtin_option(keys::OPTION_HIDE_SERVER_SETTINGS),
            "Y"
        );
        assert!(crate::get_api_server(String::new(), SERVER.to_owned()).is_empty());
        for key in [
            keys::OPTION_HIDE_NETWORK_SETTINGS,
            keys::OPTION_HIDE_SECURITY_SETTINGS,
        ] {
            assert_eq!(crate::ui_interface::get_builtin_option(key), "Y");
        }
        assert_eq!(
            crate::ui_interface::get_builtin_option(
                keys::OPTION_ENABLE_PERM_CHANGE_IN_ACCEPT_WINDOW
            ),
            "N"
        );
        config::Config::set_option(keys::OPTION_ACCESS_MODE.to_owned(), "view".to_owned());
        assert_eq!(config::Config::get_option(keys::OPTION_ACCESS_MODE), "full");
        for key in [
            keys::OPTION_ENABLE_KEYBOARD,
            keys::OPTION_ENABLE_CLIPBOARD,
            keys::OPTION_ENABLE_FILE_TRANSFER,
            keys::OPTION_ENABLE_AUDIO,
            keys::OPTION_ENABLE_CAMERA,
            keys::OPTION_ENABLE_TERMINAL,
            keys::OPTION_ENABLE_TUNNEL,
            keys::OPTION_ENABLE_REMOTE_RESTART,
            keys::OPTION_ENABLE_RECORD_SESSION,
            keys::OPTION_ENABLE_BLOCK_INPUT,
            keys::OPTION_ENABLE_PRIVACY_MODE,
            keys::OPTION_ENABLE_REMOTE_PRINTER,
        ] {
            assert!(crate::server::Connection::is_permission_enabled_locally(
                key
            ));
        }
        assert!(!config::use_ws());
        assert!(!crate::is_udp_disabled());
        assert!(config::Config::get_socks().is_none());
        assert!(crate::get_tcp_punch_enabled());
        assert!(!crate::get_udp_punch_enabled());
        assert!(!crate::get_ipv6_punch_enabled());
        assert!(!crate::get_webrtc_enabled());
    }
}
