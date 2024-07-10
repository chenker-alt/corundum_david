#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "lib/mqnic/mqnic.h"

#define TEMPLATE_APP_ID 0x12342002

static void usage(char *name)
{
    fprintf(stderr,
        "usage: %s [options]\n"
        " -d name    device to open (/dev/mqnic0)\n"
        " -r addr    read from register at addr\n"
        " -w addr    write to register at addr\n"
        " -v value   value to write (prefix with 0x for hex, 0b for binary)\n",
        name);
}

uint32_t parse_value(const char *str)
{
    if (strncmp(str, "0x", 2) == 0 || strncmp(str, "0X", 2) == 0)
        return strtoul(str + 2, NULL, 16);
    else if (strncmp(str, "0b", 2) == 0 || strncmp(str, "0B", 2) == 0)
        return strtoul(str + 2, NULL, 2);
    else
        return strtoul(str, NULL, 10);
}

int main(int argc, char *argv[])
{
    char *name;
    int opt;

    char *device = NULL;
    uint32_t read_addr = 0xFFFFFFFF;
    uint32_t write_addr = 0xFFFFFFFF;
    char *value_str = NULL;
    uint32_t value = 0;
    int do_read = 0, do_write = 0;

    struct mqnic *dev;

    name = strrchr(argv[0], '/');
    name = name ? 1+name : argv[0];

    while ((opt = getopt(argc, argv, "d:r:w:v:h?")) != EOF)
    {
        switch (opt)
        {
        case 'd':
            device = optarg;
            break;
        case 'r':
            read_addr = strtoul(optarg, NULL, 0);
            do_read = 1;
            break;
        case 'w':
            write_addr = strtoul(optarg, NULL, 0);
            do_write = 1;
            break;
        case 'v':
            value_str = optarg;
            break;
        case 'h':
        case '?':
            usage(name);
            return 0;
        default:
            usage(name);
            return -1;
        }
    }

    if (!device)
    {
        fprintf(stderr, "Device not specified\n");
        usage(name);
        return -1;
    }

    dev = mqnic_open(device);

    if (!dev)
    {
        fprintf(stderr, "Failed to open device\n");
        return -1;
    }

    // Print additional information only if no read/write operation is specified
    if (!do_read && !do_write)
    {
        if (dev->pci_device_path)
        {
            char *ptr = strrchr(dev->pci_device_path, '/');
            if (ptr)
                printf("PCIe ID: %s\n", ptr+1);
        }

        mqnic_print_fw_id(dev);

        if (!dev->app_regs)
        {
            fprintf(stderr, "Application section not present\n");
            goto err;
        }

        if (dev->app_id != TEMPLATE_APP_ID)
        {
            fprintf(stderr, "Unexpected application id (expected 0x%08x, got 0x%08x)\n", TEMPLATE_APP_ID, dev->app_id);
            goto err;
        }

        printf("App regs size: %ld\n", dev->app_regs_size);
        printf("App regs pointer: %p\n", dev->app_regs);
    }

    // Parse the value according to the specified format
    if (do_write && value_str)
        value = parse_value(value_str);

    if (do_write && write_addr != 0xFFFFFFFF)
    {
        printf("Write 0x%08x to register 0x%08x\n", value, write_addr);
        mqnic_reg_write32(dev->app_regs, write_addr, value);
    }

    if (do_read && read_addr != 0xFFFFFFFF)
    {
        printf("Read from register 0x%08x\n", read_addr);
        printf("Value: 0x%08x\n", mqnic_reg_read32(dev->app_regs, read_addr));
    }

err:
    mqnic_close(dev);
    return 0;
}
