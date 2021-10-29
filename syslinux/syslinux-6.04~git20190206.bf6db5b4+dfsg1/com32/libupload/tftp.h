#include <stdint.h>

#ifndef UPLOAD_TFTP
#define UPLOAD_TFTP

/* TFTP Error codes in host byte order */
enum tftp_error_codes {
TFTP_ERR_UNKNOWN_ERROR = 0, // We have to use the message from the server
TFTP_ERR_FILE_NOT_FOUND	= 1, /**< File not found */
TFTP_ERR_ACCESS_DENIED = 2, /**< Access violation */
TFTP_ERR_DISK_FULL = 3, /**< Disk full or allocation exceeded */
TFTP_ERR_ILLEGAL_OP = 4, /**< Illegal TFTP operation */
TFTP_ERR_UNKNOWN_TID = 5, /**< Unknown transfer ID */
TFTP_ERR_FILE_EXISTS = 6, /**< File already exists */
TFTP_ERR_UNKNOWN_USER = 7, /**< No such user */
TFTP_ERR_BAD_OPTS = 8, /**< Option negotiation failed */

/* The following are not defined in RFC, for internal usage only */
TFTP_ERR_UNABLE_TO_RESOLVE = 9,
TFTP_ERR_UNABLE_TO_CONNECT = 10,
TFTP_ERR_OK = 11,
TFTP_ERR_NO_NETWORK = 12,
};

extern const char *tftp_string_error_message[];
#endif
