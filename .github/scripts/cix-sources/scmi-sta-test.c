// SPDX-License-Identifier: GPL-2.0-only
/* Host harness for the two functions extracted from a replayed kernel tree. */
#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <string.h>

typedef void *acpi_handle;
typedef int acpi_status;
#define AE_OK 0
#define AE_NOT_FOUND 1
#define AE_BAD_PARAMETER 2
#define ACPI_FAILURE(status) ((status) != AE_OK)
#define ACPI_STA_DEFAULT 0x0f
#define pr_info(...) ((void)0)
#define pr_debug(...) ((void)0)
#define EXPORT_SYMBOL(...)

struct acpi_device_id {
	const char *id;
	unsigned long data;
};

struct acpi_device {
	const char *hid;
	int uid;
	struct acpi_device *parent;
	acpi_handle handle;
	struct {
		bool present;
		bool enabled;
		bool functional;
	} status;
	bool dep_unmet;
};

static bool firmware_status_read;
static unsigned long long firmware_status, installed_status;
static acpi_status lookup_status;
static acpi_status firmware_status_result;
static struct acpi_device controller = { .hid = "CIXHA006", .handle = &controller };

static int acpi_match_device_ids(struct acpi_device *dev, const struct acpi_device_id *ids)
{
	for (; ids->id; ids++)
		if (!strcmp(dev->hid, ids->id))
			return 0;
	return -ENODEV;
}

static struct acpi_device *acpi_dev_parent(struct acpi_device *dev) { return dev->parent; }
static bool acpi_dev_uid_match(struct acpi_device *dev, int uid) { return dev->uid == uid; }
static bool acpi_device_is_battery(struct acpi_device *dev) { return !strcmp(dev->hid, "PNP0C0A"); }

static bool acpi_dev_hid_uid_match(struct acpi_device *dev, const char *hid, const char *uid)
{
	assert(!uid);
	return !strcmp(dev->hid, hid);
}

static acpi_status acpi_get_handle(acpi_handle parent, const char *path, acpi_handle *out)
{
	assert(firmware_status_read && parent == controller.handle && !strcmp(path, "^SCMS"));
	*out = parent;
	return lookup_status;
}

static bool acpi_device_override_status(struct acpi_device *dev, unsigned long long *status)
{
	(void)dev;
	(void)status;
	return false;
}

static acpi_status acpi_bus_get_status_handle(acpi_handle handle, unsigned long long *status)
{
	assert(handle);
	firmware_status_read = true;
	*status = firmware_status;
	return firmware_status_result;
}

static void acpi_set_device_status(struct acpi_device *dev, unsigned long long status)
{
	(void)dev;
	assert(firmware_status_read);
	installed_status = status;
}

#include "scmi-sta-under-test.c"

static void check(struct acpi_device *dev, int lookup, int native, int expected)
{
	lookup_status = lookup;
	firmware_status = native;
	firmware_status_read = false;
	assert(acpi_bus_get_status(dev) == 0);
	assert(installed_status == (unsigned int)expected);
}

int main(void)
{
	struct acpi_device child = { .parent = &controller, .handle = &child };
	const char *protocols[] = { "CIXHA008", "CIXHA009" };

	for (unsigned int i = 0; i < sizeof(protocols) / sizeof(protocols[0]); i++) {
		child.hid = protocols[i];
		check(&child, AE_OK, 0, 0);
		check(&child, AE_OK, 0x0b, 0x0b);
		check(&child, AE_NOT_FOUND, 0, ACPI_STA_DEFAULT);
		check(&child, AE_NOT_FOUND, 0x0b, 0x0b);
		check(&child, AE_BAD_PARAMETER, 0, 0);
	}

	child.uid = 1;
	check(&child, AE_NOT_FOUND, 0, 0);
	child.uid = 0;
	child.parent = NULL;
	check(&child, AE_NOT_FOUND, 0, 0);
	child.parent = &controller;
	child.hid = "CIXHA007";
	check(&child, AE_NOT_FOUND, 0, 0);

	firmware_status_result = AE_BAD_PARAMETER;
	assert(acpi_bus_get_status(&child) == -ENODEV);
	return 0;
}
