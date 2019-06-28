#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <getopt.h>
#include <string.h>

struct EMHeader
{
    uint8_t machine_code;
    uint8_t general_purpose;
    uint8_t unused_1;
    uint8_t data_type;
    uint32_t dimension_x;
    uint32_t dimension_y;
    uint32_t dimension_z;
    char comment[80];
    int32_t user_params[40];
    char user_data[256];
};

int main(int argc, char **argv)
{
    int getopt_status;
    int help_flag = 0;
    int size_flag = 0;
    int motl_row = 0;
    char motl_fn[256];

    while (1)
    {
        static struct option long_options[] =
        {
            {"help", no_argument, 0, 'h'},
            {"size", no_argument, 0, 's'},
            {"row", required_argument, 0, 'r'},
            {0, 0, 0, 0}
        };

        int option_index = 0;

        getopt_status = getopt_long(argc, argv, "hsr:",
                                    long_options, &option_index);

        if (getopt_status == -1)
        {
            break;
        }

        switch (getopt_status)
        {
            case 'h':
                help_flag = 1;
                break;

            case 's':
                size_flag = 1;
                break;

            case 'r':
                motl_row = atoi(optarg);
                break;

            case '?':
                break;

            default:
                abort();
        }
    }

    if (help_flag == 1)
    {
        fprintf(stderr, "USAGE: motl_dump ");
        fprintf(stderr, "[-h, --help] [-s, --size] [-r, --row] ");
        fprintf(stderr, "<motl_filename>\n");
        return 0;
    }

    if (motl_row < 0 && motl_row > 20)
    {
        fprintf(stderr, "ERROR: Invalid MOTL row requested.\n");
        fprintf(stderr, "USAGE: motl_dump ");
        fprintf(stderr, "[-h, --help] [-s, --size] [-r, --row] ");
        fprintf(stderr, "<motl_filename>\n");
        return 1;
    }

    if (optind < argc)
    {
        if (strlen(argv[optind]) >= 256)
        {
            fprintf(stderr, "%s is too long a filename!\n", argv[optind]);
            return 1;
        }
        else
        {
            strcpy(motl_fn, argv[optind]);
        }

        FILE *motl;

        motl = fopen(motl_fn, "rb");
        if (!motl)
        {
            fprintf(stderr, "Could not open filename %s!\n", motl_fn);
            return 1;
        }

        struct EMHeader motl_header;
        fread(&motl_header, sizeof(motl_header), 1, motl);

        if (size_flag == 1)
        {
            fprintf(stdout, "%d\n", motl_header.dimension_y);
            fclose(motl);
            return 0;
        }

        float motive[20];
        int motive_idx;
        for (motive_idx = 0; motive_idx < motl_header.dimension_y; motive_idx++)
        {
            fread(&motive, sizeof(motive), 1, motl);

            if (motl_row == 0)
            {
                fprintf(stdout, "%f\t%d\t%d\t%d\t", motive[0], (int)motive[1],
                        (int)motive[2], (int)motive[3]);
                fprintf(stdout, "%d\t%d\t%d\t", (int)motive[4], (int)motive[5],
                        (int)motive[6]);
                fprintf(stdout, "%d\t%d\t%d\t", (int)motive[7], (int)motive[8],
                        (int)motive[9]);
                fprintf(stdout, "%f\t%f\t%f\t", motive[10], motive[11],
                        motive[12]);
                fprintf(stdout, "%f\t%f\t%f\t", motive[13], motive[14],
                        motive[15]);
                fprintf(stdout, "%f\t%f\t%f\t%d\n", motive[16], motive[17],
                        motive[18], (int)motive[19]);
            }
            else
            {
                int row = motl_row - 1;
                switch (motl_row)
                {
                    case 1:
                    case 10:
                    case 11:
                    case 12:
                    case 13:
                    case 14:
                    case 15:
                    case 16:
                    case 17:
                    case 18:
                    case 19:
                        fprintf(stdout, "%f\n", motive[row]);
                        break;
                    case 2:
                    case 3:
                    case 4:
                    case 5:
                    case 6:
                    case 7:
                    case 8:
                    case 9:
                    case 20:
                        fprintf(stdout, "%d\n", (int)motive[row]);
                        break;
                    default:
                        fclose(motl);
                        abort();
                }
            }
        }
        fclose(motl);
        return 0;
    }
    else
    {
        fprintf(stderr, "USAGE: motl_dump ");
        fprintf(stderr, "[-h, --help] [-s, --size] [-r, --row] ");
        fprintf(stderr, "<motl_filename>\n");
        return 1;
    }
}
