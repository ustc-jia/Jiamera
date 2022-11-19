#include "Kernel.cuh"
#include "sm_20_atomic_functions.h"

namespace Jiamera {
    extern Jiamera::Frame* frame_chief;

    __host__ void CudaPreWork(Voxel* voxel, Frame* frame) {
        // 体素块属性数组
        {
            if (cudaSuccess != cudaMalloc(&d_color_b, voxel->get_grid_num() * sizeof(float))) printf("d_color_b Malloc error.\n");    // __constant__ 变量不可在此使用
            if (cudaSuccess != cudaMemcpy(d_color_b, voxel->color_b_, voxel->get_grid_num() * sizeof(float), cudaMemcpyHostToDevice)) printf("d_color_b Memcpy error.\n");

            if (cudaSuccess != cudaMalloc(&d_color_g, voxel->get_grid_num() * sizeof(float))) printf("d_color_g Malloc error.\n");
            if (cudaSuccess != cudaMemcpy(d_color_g, voxel->color_g_, voxel->get_grid_num() * sizeof(float), cudaMemcpyHostToDevice)) printf("d_color_g Memcpy error.\n");

            if (cudaSuccess != cudaMalloc(&d_color_r, voxel->get_grid_num() * sizeof(float))) printf("d_color_r Malloc error.\n");
            if (cudaSuccess != cudaMemcpy(d_color_r, voxel->color_r_, voxel->get_grid_num() * sizeof(float), cudaMemcpyHostToDevice)) printf("d_color_r Memcpy error.\n");

            if (cudaSuccess != cudaMalloc(&d_instance, voxel->get_grid_num() * sizeof(int))) printf("d_instance Malloc error.\n");
            if (cudaSuccess != cudaMemcpy(d_instance, voxel->instance_, voxel->get_grid_num() * sizeof(int), cudaMemcpyHostToDevice)) printf("d_instance Memcpy error.\n");

            if (cudaSuccess != cudaMalloc(&d_label, voxel->get_grid_num() * sizeof(int))) printf("d_label Malloc error.\n");
            if (cudaSuccess != cudaMemcpy(d_label, voxel->label_, voxel->get_grid_num() * sizeof(int), cudaMemcpyHostToDevice)) printf("d_label Memcpy error.\n");

            if (cudaSuccess != cudaMalloc(&d_tsdf, voxel->get_grid_num() * sizeof(float))) printf("d_tsdf Malloc error.\n");
            if (cudaSuccess != cudaMemcpy(d_tsdf, voxel->tsdf_, voxel->get_grid_num() * sizeof(float), cudaMemcpyHostToDevice)) printf("d_tsdf Memcpy error.\n");

            if (cudaSuccess != cudaMalloc(&d_bgr_weight, voxel->get_grid_num() * sizeof(float))) printf("d_bgr_weight Malloc error.\n");
            if (cudaSuccess != cudaMemcpy(d_bgr_weight, voxel->bgr_weight_, voxel->get_grid_num() * sizeof(float), cudaMemcpyHostToDevice)) printf("d_bgr_weight Memcpy error.\n");

            if (cudaSuccess != cudaMalloc(&d_label_weight, voxel->get_grid_num() * sizeof(float))) printf("d_label_weight Malloc error.\n");
            if (cudaSuccess != cudaMemcpy(d_label_weight, voxel->label_weight_, voxel->get_grid_num() * sizeof(float), cudaMemcpyHostToDevice)) printf("d_label_weight Memcpy error.\n");

            if (cudaSuccess != cudaMalloc(&d_instance_weight, voxel->get_grid_num() * sizeof(float))) printf("d_instance_weight Malloc error.\n");
            if (cudaSuccess != cudaMemcpy(d_instance_weight, voxel->instance_weight_, voxel->get_grid_num() * sizeof(float), cudaMemcpyHostToDevice)) printf("d_instance_weight Memcpy error.\n");
        }

        // 点云数组
        {
            if (cudaSuccess != cudaMalloc((void**)&d_gl_rgb, voxel->get_grid_num() * sizeof(float) * 6 / 100))  printf("d_gl_rgb Malloc error.\n");
            if (cudaSuccess != cudaMalloc((void**)&d_gl_label, voxel->get_grid_num() * sizeof(float) * 6 / 100))  printf("d_gl_label Malloc error.\n");
            if (cudaSuccess != cudaMalloc((void**)&d_gl_instance, voxel->get_grid_num() * sizeof(float) * 6 / 100))  printf("d_gl_instance Malloc error.\n");

            if (cudaSuccess != cudaMalloc(&d_gl_point_num, sizeof(unsigned int))) printf("d_gl_point_num Malloc error.\n");

        }

        // 帧图片数组
        {
            if (cudaSuccess != cudaMemcpyToSymbol(d_rgb_height, &frame->rgb_height_, sizeof(int))) printf("d_rgb_height MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_rgb_width, &frame->rgb_width_, sizeof(int))) printf("d_rgb_width MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_rgb_intrinsics, frame->rgb_viewer_->intrinsics_->grid_, sizeof(float) * 9)) printf("d_rgb_intrinsics MemcpyToSymbol error.\n");

            if (cudaSuccess != cudaMemcpyToSymbol(d_depth_height, &frame->depth_height_, sizeof(int))) printf("d_depth_height MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_depth_width, &frame->depth_width_, sizeof(int))) printf("d_depth_width MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_depth_intrinsics, frame->depth_viewer_->intrinsics_->grid_, sizeof(float) * 9)) printf("d_depth_intrinsics MemcpyToSymbol error.\n");

            if (cudaSuccess != cudaMemcpyToSymbol(d_panoptic_height, &frame->panoptic_height_, sizeof(int))) printf("d_panoptic_height MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_panoptic_width, &frame->panoptic_width_, sizeof(int))) printf("d_panoptic_width MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_panoptic_intrinsics, frame->panoptic_viewer_->intrinsics_->grid_, sizeof(float) * 9)) printf("d_panoptic_intrinsics MemcpyToSymbol error.\n");

            if (cudaSuccess != cudaMalloc((void**)&d_pose, 4 * 4 * sizeof(float))) printf("d_pose Malloc error.\n");
            if (cudaSuccess != cudaMalloc((void**)&d_rgb_image, frame->rgb_height_ * frame->rgb_width_ * sizeof(float) * 3)) printf("d_rgb_image Malloc error.\n");
            if (cudaSuccess != cudaMalloc((void**)&d_depth_image, frame->depth_height_ * frame->depth_width_ * sizeof(float))) printf("d_depth_image Malloc error.\n");
            if (cudaSuccess != cudaMalloc((void**)&d_panoptic_image, frame->panoptic_height_ * frame->panoptic_width_ * sizeof(float) * 3)) printf("d_panoptic_image Malloc error.\n");

            #ifdef GPU_PROCESS_IMAGE_
            if (cudaSuccess != cudaMalloc((void**)&d_rgb_uchar, frame->rgb_height_ * frame->rgb_width_ * sizeof(uchar) * 3)) printf("d_rgb_uchar Malloc error.\n");
            if (cudaSuccess != cudaMalloc((void**)&d_depth_uchar, frame->depth_height_ * frame->depth_width_ * sizeof(uchar) * 2)) printf("d_depth_uchar Malloc error.\n");
            if (cudaSuccess != cudaMalloc((void**)&d_panoptic_uchar, frame->panoptic_height_ * frame->panoptic_width_ * sizeof(uchar) * 3)) printf("d_panoptic_uchar Malloc error.\n");
            #endif
        }

        // 空间属性数组
        {
            if (cudaSuccess != cudaMemcpyToSymbol(d_grid_num_x, &voxel->grid_num_x_, sizeof(int))) printf("d_grid_num_x MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_grid_num_y, &voxel->grid_num_y_, sizeof(int))) printf("d_grid_num_y MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_grid_num_z, &voxel->grid_num_z_, sizeof(int))) printf("d_grid_num_z MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_origin_x, &voxel->k_origin_x_, sizeof(float))) printf("d_origin_x MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_origin_y, &voxel->k_origin_y_, sizeof(float))) printf("d_origin_y MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_origin_z, &voxel->k_origin_z_, sizeof(float))) printf("d_origin_z MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_grid_size, &voxel->k_grid_size_, sizeof(float))) printf("d_grid_size MemcpyToSymbol error.\n");
            if (cudaSuccess != cudaMemcpyToSymbol(d_trunc_margin, &voxel->truncation_margin_, sizeof(float))) printf("d_trunc_margin MemcpyToSymbol error.\n");
        }
    }

    __host__ void CudaInWork(Voxel* voxel, Frame* chief_frame, std::vector<Frame*> frame_list) {

        int frame_num = chief_frame->last_frame_index_ - chief_frame->first_frame_index_ + 1;
        long long t1 = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
        std::vector<std::thread>frame_processor(FRAME_NUM_);

        for (size_t i = chief_frame->first_frame_index_; i <= chief_frame->last_frame_index_; i += FRAME_NUM_) {
            //std::cout << "1 " << std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count() << std::endl;

            for (int j = 0; j < FRAME_NUM_; ++j) {
                if (i + j > chief_frame->last_frame_index_) break;
                frame_processor[j] = std::move(std::thread{&Frame::Update, frame_list[j], i + j});
            }

            for (size_t j = 0; j < FRAME_NUM_; ++j) {
                if (i + j > chief_frame->last_frame_index_) break;
                frame_processor[j].join();
                frame_processor[j].~thread();

                Frame* frame = frame_list[j];
                cv::Mat rgb_mat = frame_list[j]->rgb_mat_;
                cv::Mat depth_mat = frame_list[j]->depth_mat_;
                cv::Mat panoptic_mat = frame_list[j]->panoptic_mat_;

                // if (i % 10 == 0) std::cout << "\nFrame" << i + j << "-----------------------------------------\n";

                //cudaMallocManaged()
                if (cudaSuccess != cudaMemcpy(d_pose, frame->rgb_viewer_->get_pose(), 4 * 4 * sizeof(float), cudaMemcpyHostToDevice)) printf("d_pose Memcpy error.\n");
               
                #ifdef GPU_PROCESS_IMAGE_
                    if (cudaSuccess != cudaMemcpy(d_rgb_uchar, rgb_mat.data, chief_frame->rgb_height_ * chief_frame->rgb_width_ * sizeof(uchar) * 3, cudaMemcpyHostToDevice)) printf("d_rgb_uchar Memcpy error.\n");   // 3 ms
                    if (cudaSuccess != cudaMemcpy(d_depth_uchar, depth_mat.data, chief_frame->depth_height_ * chief_frame->depth_width_ * sizeof(uchar) * 2, cudaMemcpyHostToDevice)) printf("d_depth_uchar Memcpy error.\n");
                    if (cudaSuccess != cudaMemcpy(d_panoptic_uchar, panoptic_mat.data, chief_frame->panoptic_height_ * chief_frame->panoptic_width_ * sizeof(uchar) * 3, cudaMemcpyHostToDevice)) printf("d_panoptic_uchar Memcpy error.\n");

                    dim3 RgbSize(chief_frame->rgb_width_, chief_frame->rgb_height_);
                    ProcessImage << <RgbSize, 3 >> > (d_rgb_uchar, d_rgb_image, 1, frame->rgb_mat_.step);

                    dim3 DepthSize(chief_frame->depth_width_, chief_frame->depth_height_);
                    ProcessImage << <DepthSize, 1 >> > (d_depth_uchar, d_depth_image, 2, frame->depth_mat_.step);

                    dim3 PanopticSize(chief_frame->panoptic_width_, chief_frame->panoptic_height_);
                    ProcessImage << <PanopticSize, 3 >> > (d_panoptic_uchar, d_panoptic_image, 3, frame->panoptic_mat_.step);
                #else
                if (cudaSuccess != cudaMemcpy(d_rgb_image, frame->rgb_image_, frame->rgb_height_ * frame->rgb_width_ * sizeof(float) * 3, cudaMemcpyHostToDevice)) printf("d_rgb_image Memcpy error.\n");   // 3 ms
                if (cudaSuccess != cudaMemcpy(d_depth_image, frame->depth_image_, frame->depth_height_ * frame->depth_width_ * sizeof(float), cudaMemcpyHostToDevice)) printf("d_depth_image Memcpy error.\n");
                if (cudaSuccess != cudaMemcpy(d_panoptic_image, frame->panoptic_image_, frame->panoptic_height_ * frame->panoptic_width_ * sizeof(float) * 3, cudaMemcpyHostToDevice)) printf("d_panoptic_image Memcpy error.\n");
                #endif

                if (cudaSuccess != cudaMemcpy(d_gl_point_num, new int(0), sizeof(unsigned int), cudaMemcpyHostToDevice)) printf("d_gl_rgb_num Memcpy error.\n");

                dim3 dimGrid(voxel->grid_num_y_, voxel->grid_num_z_);
                dim3 dimBlock(voxel->grid_num_x_);

                DeviceMain << < dimGrid, dimBlock >> > (i, d_color_b, d_color_g, d_color_r, d_instance, d_label, d_tsdf, d_bgr_weight, d_label_weight, d_instance_weight,
                    d_pose, d_rgb_image, d_depth_image, d_panoptic_image,
                    d_gl_rgb, d_gl_label, d_gl_instance, d_gl_point_num);
                // cudaDeviceSynchronize();

                if (cudaSuccess != cudaMemcpy(&voxel->gl_point_num_, d_gl_point_num, sizeof(unsigned int), cudaMemcpyDeviceToHost)) printf("d_gl_rgb_num MemcpyToHost error.\n");

                if ((i + j) % 10 == 0) std::cout << "\nFrame " << i + j << ": " << voxel->gl_point_num_ << " points.\n";

                voxel->gl_data_mtx_.lock();    // 等待直到获得锁
                if (cudaSuccess != cudaMemcpy(voxel->gl_rgb_, d_gl_rgb, voxel->gl_point_num_ * sizeof(float) * 6, cudaMemcpyDeviceToHost)) printf("d_gl_rgb MemcpyToHost error.\n");
                if (cudaSuccess != cudaMemcpy(voxel->gl_label_, d_gl_label, voxel->gl_point_num_ * sizeof(float) * 6, cudaMemcpyDeviceToHost)) printf("d_gl_label MemcpyToHost error.\n");
                if (cudaSuccess != cudaMemcpy(voxel->gl_instance_, d_gl_instance, voxel->gl_point_num_ * sizeof(float) * 6, cudaMemcpyDeviceToHost)) printf("d_gl_instance MemcpyToHost error.\n");
                voxel->gl_data_mtx_.unlock();

                voxel->gl_data_update();
                
            }
        }
        long long t2 = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();

        double speed = double(t2 - t1) / (double)frame_num;
        std::cout << "Average speed: " << speed << " ms / frame.\n";
    }
    __host__ void CudaPostWork(Voxel* voxel, Frame* chief_frame, std::vector<Jiamera::Frame*> frame_list) {
        //if (cudaSuccess != cudaMemcpy(voxel->data_, d_data, voxel->grid_num_ * sizeof(float) * voxel->attrib_num_, cudaMemcpyDeviceToHost)) printf("d_data MemcpyToHost error.\n");

        //if (cudaSuccess != cudaFree(d_data)) printf("d_data free error.\n");
        //if (cudaSuccess != cudaFree(d_max_data)) printf("d_max_data free error.\n");
        //if (cudaSuccess != cudaFree(d_min_data)) printf("d_min_data free error.\n");

        //if (cudaSuccess != cudaFree(d_rgb_intrinsics)) printf("d_rgb_intrinsics free error.\n");
        //if (cudaSuccess != cudaFree(d_depth_intrinsics)) printf("d_depth_intrinsics free error.\n");

        //if (cudaSuccess != cudaFree(d_pose)) printf("d_pose free error.\n");

        //if (cudaSuccess != cudaFree(d_rgb_data)) printf("d_rgb_data free error.\n");
        //if (cudaSuccess != cudaFree(d_depth_data)) printf("d_depth_data free error.\n");
    }

    __global__ void DeviceMain(const int index, float* color_b, float* color_g, float* color_r, int* instance, int* label, float* tsdf, float* bgr_weight, float* label_weight, float* instance_weight,
        float* pose, float* rgb_image, float* depth_image, float* panoptic_image,
        float* gl_rgb, float* gl_label, float* gl_instance, unsigned int* gl_point_num) {

        int blockId = blockIdx.y * gridDim.x + blockIdx.x;
        int threadId = blockId * blockDim.x + threadIdx.x;
        int voxel_index = threadId;

        bool update_rgb = true;
        bool update_label = true;
        bool update_instance = true;

        float best_diff, best_dist;
        float best_r_current, best_g_current, best_b_current;
        int best_label_current;
        int best_instance_current;
        float best_label_weight_current;

#ifdef MULTI_SAMPLE_AA_
        /*
        * 每个体素块细均匀取 27 个小点，计算每个小点的各个属性值
        * 更新过程中只要中点不符合要求就略过
        */
        bool valid_point[d_sub_point_num];  // 记录每个点是否有效
        for (size_t idx = 0; idx < d_sub_point_num; ++idx) valid_point[idx] = true;
        int valid_num = d_sub_point_num;

        int rgb_x[d_sub_point_num], rgb_y[d_sub_point_num];
        int depth_x[d_sub_point_num], depth_y[d_sub_point_num];
        int panoptic_x[d_sub_point_num], panoptic_y[d_sub_point_num];
        float world_x[d_sub_point_num], world_y[d_sub_point_num], world_z[d_sub_point_num];
        float camera_x[d_sub_point_num], camera_y[d_sub_point_num], camera_z[d_sub_point_num];

        float depth[d_sub_point_num];
        float r_current[d_sub_point_num], g_current[d_sub_point_num], b_current[d_sub_point_num];
        float label_current[d_sub_point_num], instance_current[d_sub_point_num], label_weight_current[d_sub_point_num];

        // 计算坐标
        if (update_rgb || update_label || update_instance) {

            world_x[0] = d_origin_x + d_grid_size * threadIdx.x;
            world_y[0] = d_origin_y + d_grid_size * blockIdx.x;
            world_z[0] = d_origin_z + d_grid_size * blockIdx.y;

            float size_offset = d_grid_size / 4/*cbrtf(d_sub_point_num)*/;

            for (size_t idx = 1; idx < d_sub_point_num; ++idx) {
                world_x[idx] = world_x[0] + X[idx] * size_offset;
                world_y[idx] = world_y[0] + Y[idx] * size_offset;
                world_z[idx] = world_z[0] + Z[idx] * size_offset;
            }

            for (size_t idx = 0; idx < d_sub_point_num; ++idx) {
                if (!valid_point[idx]) continue;
                camera_x[idx] = pose[0 * 4 + 0] * (world_x[idx] - pose[0 * 4 + 3]) +
                    pose[1 * 4 + 0] * (world_y[idx] - pose[1 * 4 + 3]) +
                    pose[2 * 4 + 0] * (world_z[idx] - pose[2 * 4 + 3]);

                camera_y[idx] = pose[0 * 4 + 1] * (world_x[idx] - pose[0 * 4 + 3]) +
                    pose[1 * 4 + 1] * (world_y[idx] - pose[1 * 4 + 3]) +
                    pose[2 * 4 + 1] * (world_z[idx] - pose[2 * 4 + 3]);

                camera_z[idx] = pose[0 * 4 + 2] * (world_x[idx] - pose[0 * 4 + 3]) +
                    pose[1 * 4 + 2] * (world_y[idx] - pose[1 * 4 + 3]) +
                    pose[2 * 4 + 2] * (world_z[idx] - pose[2 * 4 + 3]);

                if (camera_z[idx] <= 0) {
                    valid_point[idx] = false;
                    --valid_num;
                }
            }
            if (camera_z[0] <= 0) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 rgb
        if (update_rgb || update_label || update_instance) {
            for (size_t idx = 0; idx < d_sub_point_num; ++idx) {
                if (!valid_point[idx]) continue;

                rgb_x[idx] = roundf(d_rgb_intrinsics[0 * 3 + 0] * (camera_x[idx] / camera_z[idx]) + d_rgb_intrinsics[0 * 3 + 2]);
                rgb_y[idx] = roundf(d_rgb_intrinsics[1 * 3 + 1] * (camera_y[idx] / camera_z[idx]) + d_rgb_intrinsics[1 * 3 + 2]);

                if (rgb_x[idx] < 0 || rgb_x[idx] >= d_rgb_width || rgb_y[idx] < 0 || rgb_y[idx] >= d_rgb_height) {
                    valid_point[idx] = false;
                    --valid_num;
                    continue;
                }

                int color_index = (rgb_y[idx] * d_rgb_width + rgb_x[idx]) * 3;
                b_current[idx] = rgb_image[color_index + 0];
                g_current[idx] = rgb_image[color_index + 1];
                r_current[idx] = rgb_image[color_index + 2];
            }
            if (rgb_x[0] < 0 || rgb_x[0] >= d_rgb_width || rgb_y[0] < 0 || rgb_y[0] >= d_rgb_height) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 panoptic
        if (update_label || update_instance) {
            for (size_t idx = 0; idx < d_sub_point_num; ++idx) {
                if (!valid_point[idx]) continue;

                panoptic_x[idx] = rgb_x[idx];
                panoptic_y[idx] = rgb_y[idx];

                int panoptic_index = (panoptic_y[idx] * d_panoptic_width + panoptic_x[idx]) * 3;
                instance_current[idx] = panoptic_image[panoptic_index + 0];
                label_current[idx] = panoptic_image[panoptic_index + 1];
                label_weight_current[idx] = panoptic_image[panoptic_index + 2];
            }

            if (label_weight_current[0] == 0.0f) update_label = false;
        }

        // 计算 depth
        if (update_rgb || update_label || update_instance) {
            for (size_t idx = 0; idx < d_sub_point_num; ++idx) {
                if (!valid_point[idx]) continue;

                depth_x[idx] = roundf(d_depth_intrinsics[0 * 3 + 0] * (camera_x[idx] / camera_z[idx]) + d_depth_intrinsics[0 * 3 + 2]);
                depth_y[idx] = roundf(d_depth_intrinsics[1 * 3 + 1] * (camera_y[idx] / camera_z[idx]) + d_depth_intrinsics[1 * 3 + 2]);
                if (depth_x[idx] < 0 || depth_x[idx] >= d_depth_width || depth_y[idx] < 0 || depth_y[idx] >= d_depth_height) {
                    valid_point[idx] = false;
                    --valid_num;
                    continue;
                }

                depth[idx] = depth_image[depth_y[idx] * d_depth_width + depth_x[idx]];
                if (depth[idx] <= 0 || depth[idx] >= 10) {
                    valid_point[idx] = false;
                    --valid_num;
                }
            }

            if (depth_x[0] < 0 || depth_x[0] >= d_depth_width || depth_y[0] < 0 || depth_y[0] >= d_depth_height || depth[0] <= 0 || depth[0] >= 10) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 best 值
        if (update_rgb || update_label || update_instance) {

            best_r_current = r_current[0];
            best_g_current = g_current[0];
            best_b_current = b_current[0];

            best_label_current = GetMajorityLabel(valid_point, label_current, d_sub_point_num);
            //best_label_current = label_current[0];

            best_instance_current = instance_current[0];

            //best_label_weight_current = label_weight_current[0];
            best_label_weight_current = GetAverageLabelWeightByLabel(valid_point, label_weight_current, label_current, d_sub_point_num, best_label_current);

            best_diff = depth[0] - camera_z[0];
            //best_diff = GetAverageDiffByLabel(valid_point, depth, camera_z, label_current, d_sub_point_num, best_label_current);

            if (best_diff <= -d_trunc_margin) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
            else {
                best_dist = fmin(1.0f, best_diff / d_trunc_margin);   // 对 sdf 进行截断 错误
            }
        }

#else
        int rgb_x, rgb_y, depth_x, depth_y, panoptic_x, panoptic_y;
        float depth, dist;
        float camera_x, camera_y, camera_z;

        // 计算坐标
        if (update_rgb || update_label || update_instance) {
            /*
             Convert from base frame camera coordinates to current frame camera coordinates
             define: 相机位姿矩阵 = 相机外参，相机坐标 = 相机位姿 * 世界坐标
             世界坐标 -> 相机坐标
             base frame 是相机的初始坐标，根据相机的当前位姿，投影到相机的当前坐标
             此时，就可以得到该体素到相机的距离 pt_cam_z
             世界坐标 -> 相机坐标
             旋转矩阵的逆等于转置
             dimension: m
            */
            float world_x = d_origin_x + d_grid_size * threadIdx.x;
            float world_y = d_origin_y + d_grid_size * blockIdx.x;
            float world_z = d_origin_z + d_grid_size * blockIdx.y;

            camera_x = pose[0 * 4 + 0] * (world_x - pose[0 * 4 + 3]) +
                pose[1 * 4 + 0] * (world_y - pose[1 * 4 + 3]) +
                pose[2 * 4 + 0] * (world_z - pose[2 * 4 + 3]);

            camera_y = pose[0 * 4 + 1] * (world_x - pose[0 * 4 + 3]) +
                pose[1 * 4 + 1] * (world_y - pose[1 * 4 + 3]) +
                pose[2 * 4 + 1] * (world_z - pose[2 * 4 + 3]);

            camera_z = pose[0 * 4 + 2] * (world_x - pose[0 * 4 + 3]) +
                pose[1 * 4 + 2] * (world_y - pose[1 * 4 + 3]) +
                pose[2 * 4 + 2] * (world_z - pose[2 * 4 + 3]);   // 正确

            if (camera_z <= 0) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 rgb
        if (update_rgb || update_label || update_instance) {
            rgb_x = roundf(d_rgb_intrinsics[0 * 3 + 0] * (camera_x / camera_z) + d_rgb_intrinsics[0 * 3 + 2]);  //正确
            rgb_y = roundf(d_rgb_intrinsics[1 * 3 + 1] * (camera_y / camera_z) + d_rgb_intrinsics[1 * 3 + 2]);

            panoptic_x = rgb_x;
            panoptic_y = rgb_y;

            if (rgb_x < 0 || rgb_x >= d_rgb_width || rgb_y < 0 || rgb_y >= d_rgb_height) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
            else {
                int color_index = (rgb_y * d_rgb_width + rgb_x) * 3;
                best_b_current = rgb_image[color_index + 0];
                best_g_current = rgb_image[color_index + 1];
                best_r_current = rgb_image[color_index + 2];
            }
        }

        // 计算 depth
        if (update_rgb || update_label || update_instance) {
            // 相机坐标 -> depth 像素坐标
            depth_x = roundf(d_depth_intrinsics[0 * 3 + 0] * (camera_x / camera_z) + d_depth_intrinsics[0 * 3 + 2]);
            depth_y = roundf(d_depth_intrinsics[1 * 3 + 1] * (camera_y / camera_z) + d_depth_intrinsics[1 * 3 + 2]);

            if (depth_x < 0 || depth_x >= d_depth_width || depth_y < 0 || depth_y >= d_depth_height) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
            else {
                depth = depth_image[depth_y * d_depth_width + depth_x];
            }

            if (depth <= 0 || depth >= 10) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 panoptic
        if (update_label || update_instance) {
            int panoptic_index = (panoptic_y * d_panoptic_width + panoptic_x) * 3;
            best_instance_current = (int)panoptic_image[panoptic_index + 0];
            best_label_current = (int)panoptic_image[panoptic_index + 1];
            best_label_weight_current = panoptic_image[panoptic_index + 2];

            if (best_label_weight_current == 0.0f) update_label = false;
        }

        // 计算 best 值
        if (update_rgb || update_label || update_instance) {
            best_diff = (depth - camera_z);

            if (best_diff <= -d_trunc_margin) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
            else {
                best_dist = fmin(1.0f, best_diff / d_trunc_margin);
            }
        }

#endif
        // 更新 rgb 和 tsdf
        if (update_rgb) {
            float rgb_weight_old = bgr_weight[voxel_index];
            float rgb_weight_new = rgb_weight_old + 1.0f;

            float b_old = color_b[voxel_index];
            float g_old = color_g[voxel_index];
            float r_old = color_r[voxel_index];

            float b_new = (b_old * rgb_weight_old + best_b_current) / rgb_weight_new;
            float g_new = (g_old * rgb_weight_old + best_g_current) / rgb_weight_new;
            float r_new = (r_old * rgb_weight_old + best_r_current) / rgb_weight_new;

            color_b[voxel_index] = b_new;
            color_g[voxel_index] = g_new;
            color_r[voxel_index] = r_new;
            bgr_weight[voxel_index] = rgb_weight_new;

            float tsdf_old = tsdf[voxel_index];
            float tsdf_new = (tsdf_old * rgb_weight_old + best_dist) / rgb_weight_new;

            tsdf[voxel_index] = tsdf_new;
        }

        // 更新 label
        if (update_label) {
            int label_old = label[voxel_index];
            float label_weight_old = label_weight[voxel_index];

            int label_new;
            float label_weight_new;

            if (label_old == -1) {
                label_new = best_label_current;
                label_weight_new = 1.0f;
            }
            else {
                if (best_label_current == label_old) label_weight_new = label_weight_old + 1.0f;
                else label_weight_new = label_weight_old - 1.0f;

                if (label_weight_new >= 0) label_new = label_old;
                else label_new = best_label_current;
            }

            label[voxel_index] = label_new;
            label_weight[voxel_index] = label_weight_new;
        }

        // 更新 instance
        if (update_instance) {

        }

        // 更新要显示的点云
        float x = d_origin_x + d_grid_size * threadIdx.x;
        float y = d_origin_y + d_grid_size * blockIdx.x;
        float z = d_origin_z + d_grid_size * blockIdx.y;

        if (abs(tsdf[voxel_index]) >= 0.2f) return;
        if (bgr_weight[voxel_index] > 0.0f) {

            int idx = atomicInc(gl_point_num, UINT_MAX);
            gl_rgb[idx * 6 + 0] = x;
            gl_rgb[idx * 6 + 1] = y;
            gl_rgb[idx * 6 + 2] = z;
            gl_rgb[idx * 6 + 3] = color_r[voxel_index];
            gl_rgb[idx * 6 + 4] = color_g[voxel_index];
            gl_rgb[idx * 6 + 5] = color_b[voxel_index];

            float label_r, label_g, label_b;
            int L = label[voxel_index];

            if (L == 0) { label_r = 174; label_g = 199; label_b = 232; }
            else if (L == 1) { label_r = 152; label_g = 223; label_b = 138; }
            else if (L == 2) { label_r = 31; label_g = 119; label_b = 180; }
            else if (L == 3) { label_r = 255; label_g = 187; label_b = 120; }
            else if (L == 4) { label_r = 188; label_g = 189; label_b = 34; }
            else if (L == 5) { label_r = 140; label_g = 86; label_b = 75; }
            else if (L == 6) { label_r = 255; label_g = 152; label_b = 150; }
            else if (L == 7) { label_r = 214; label_g = 39; label_b = 40; }
            else if (L == 8) { label_r = 197; label_g = 176; label_b = 213; }
            else if (L == 9) { label_r = 148; label_g = 103; label_b = 189; }
            else if (L == 10) { label_r = 196; label_g = 156; label_b = 148; }
            else if (L == 11) { label_r = 23; label_g = 190; label_b = 207; }
            else if (L == 12) { label_r = 178; label_g = 76; label_b = 76; }
            else if (L == 13) { label_r = 247; label_g = 182; label_b = 210; }
            else if (L == 14) { label_r = 66; label_g = 188; label_b = 102; }
            else if (L == 15) { label_r = 219; label_g = 219; label_b = 141; }
            else if (L == 16) { label_r = 140; label_g = 57; label_b = 197; }
            else if (L == 17) { label_r = 202; label_g = 185; label_b = 52; }
            else if (L == 18) { label_r = 51; label_g = 176; label_b = 203; }
            else if (L == 19) { label_r = 200; label_g = 54; label_b = 131; }
            else if (L == 20) { label_r = 92; label_g = 193; label_b = 61; }
            else if (L == 21) { label_r = 78; label_g = 71; label_b = 183; }
            else if (L == 22) { label_r = 172; label_g = 114; label_b = 82; }
            else if (L == 23) { label_r = 255; label_g = 127; label_b = 14; }
            else if (L == 24) { label_r = 91; label_g = 163; label_b = 138; }
            else if (L == 25) { label_r = 153; label_g = 98; label_b = 156; }
            else if (L == 26) { label_r = 140; label_g = 153; label_b = 101; }
            else if (L == 27) { label_r = 158; label_g = 218; label_b = 229; }
            else if (L == 28) { label_r = 100; label_g = 125; label_b = 154; }
            else if (L == 29) { label_r = 178; label_g = 127; label_b = 135; }
            else if (L == 30) { label_r = 120; label_g = 185; label_b = 128; }
            else if (L == 31) { label_r = 146; label_g = 111; label_b = 194; }
            else if (L == 32) { label_r = 44; label_g = 160; label_b = 44; }
            else if (L == 33) { label_r = 112; label_g = 128; label_b = 144; }
            else if (L == 34) { label_r = 96; label_g = 207; label_b = 209; }
            else if (L == 35) { label_r = 227; label_g = 119; label_b = 194; }
            else if (L == 36) { label_r = 213; label_g = 92; label_b = 176; }
            else if (L == 37) { label_r = 94; label_g = 106; label_b = 211; }
            else if (L == 38) { label_r = 82; label_g = 84; label_b = 163; }
            else if (L == 39) { label_r = 100; label_g = 85; label_b = 144; }
            else { label_r = 0.0f; label_g = 0.0f; label_b = 0.0f; }

            gl_label[idx * 6 + 0] = x;
            gl_label[idx * 6 + 1] = y;
            gl_label[idx * 6 + 2] = z;
            gl_label[idx * 6 + 3] = label_r / 255.0f;
            gl_label[idx * 6 + 4] = label_g / 255.0f;
            gl_label[idx * 6 + 5] = label_b / 255.0f;

        }
    }

    __global__ void ProcessImage(const uchar* src, float* des, uint type, int step) {
        int c = blockIdx.x;
        int r = blockIdx.y;
        int channel = threadIdx.x;
        int w = gridDim.x;
        int h = gridDim.y;

        if (1 == type) {    // rgb
            des[(r * w + c) * 3 + channel] = int(src[r * step + c * 3 + channel]) / 255.0f;
        }
        else if (2 == type) {     // depth
            /*
             深度图像尺寸为 640 * 480，每个像素 2 byte，每行 640 * 2 = 1280 byte
             存储格式为：0x00 ~ 0x01 pixel 0      0x02 ~ 0x03 pixel 1     0x04 ~ 0x05 pixel 2 ...
             原始数据类型为 uchar (1 byte)，但真实值的类型为 ushort (2 byte)，
             若直接类型转换：(ushort)src[r * step + c * 2 + 1] 每次只能读取 1 byte，
             需要手动读取两个 uchar，然后拼接成一个 ushort
             */
            ushort depth_us = 0;
            depth_us = depth_us | src[r * step + c * 2 + 1];
            depth_us = depth_us << 8;
            depth_us = depth_us | src[r * step + c * 2];
            float depth_val = (float)(depth_us) / 1000.0f;
            if (depth_val > 6.0f) depth_val = 0.0f;

            des[r * w + c] = depth_val;
        }
        else {      // panoptic
            des[(r * w + c) * 3 + channel] = int(src[r * step + c * 3 + channel]);
            if (channel == 2) des[(r * w + c) * 3 + channel] /= 255.0f;
        }
        return;
    }

    __global__ void test(float* data) {
        for (int i = 80; i < 100; i++) printf("%f ", data[i]);
        printf("\n");
    }

    __device__ void UpdateData(const int voxel_index, float* color_b, float* color_g, float* color_r, int* instance, int* label, float* tsdf, float* bgr_weight, float* label_weight, float* instance_weight,
        float* pose, float* rgb_image, float* depth_image, float* panoptic_image,
        float* gl_rgb, float* gl_label, float* gl_instance, unsigned int* gl_point_num) {

        bool update_rgb = true;
        bool update_label = true;
        bool update_instance = true;

        float best_diff, best_dist;
        float best_r_current, best_g_current, best_b_current;
        int best_label_current;
        int best_instance_current;
        float best_label_weight_current;
        printf("$");

#ifdef MULTI_SAMPLE_AA_
        /*
        * 每个体素块细均匀取 27 个小点，计算每个小点的各个属性值
        * 更新过程中只要中点不符合要求就略过
        */
        bool valid_point[d_sub_point_num];  // 记录每个点是否有效
        for (size_t idx = 0; idx < d_sub_point_num; ++idx) valid_point[idx] = true;
        int valid_num = d_sub_point_num;

        int rgb_x[d_sub_point_num], rgb_y[d_sub_point_num];
        int depth_x[d_sub_point_num], depth_y[d_sub_point_num];
        int panoptic_x[d_sub_point_num], panoptic_y[d_sub_point_num];
        float world_x[d_sub_point_num], world_y[d_sub_point_num], world_z[d_sub_point_num];
        float camera_x[d_sub_point_num], camera_y[d_sub_point_num], camera_z[d_sub_point_num];

        float depth[d_sub_point_num];
        float r_current[d_sub_point_num], g_current[d_sub_point_num], b_current[d_sub_point_num];
        float label_current[d_sub_point_num], instance_current[d_sub_point_num], label_weight_current[d_sub_point_num];

        // 计算坐标
        if (update_rgb || update_label || update_instance) {

            world_x[0] = d_origin_x + d_grid_size * threadIdx.x;
            world_y[0] = d_origin_y + d_grid_size * blockIdx.x;
            world_z[0] = d_origin_z + d_grid_size * blockIdx.y;

            float size_offset = d_grid_size / cbrtf(d_sub_point_num);

            for (size_t idx = 1; idx < d_sub_point_num; ++idx) {
                world_x[idx] = world_x[0] + X[idx] * size_offset;
                world_y[idx] = world_y[0] + Y[idx] * size_offset;
                world_z[idx] = world_z[0] + Z[idx] * size_offset;
            }

            for (size_t idx = 0; idx < d_sub_point_num; ++idx) {
                if (!valid_point[idx]) continue;
                camera_x[idx] = pose[0 * 4 + 0] * (world_x[idx] - pose[0 * 4 + 3]) +
                    pose[1 * 4 + 0] * (world_y[idx] - pose[1 * 4 + 3]) +
                    pose[2 * 4 + 0] * (world_z[idx] - pose[2 * 4 + 3]);

                camera_y[idx] = pose[0 * 4 + 1] * (world_x[idx] - pose[0 * 4 + 3]) +
                    pose[1 * 4 + 1] * (world_y[idx] - pose[1 * 4 + 3]) +
                    pose[2 * 4 + 1] * (world_z[idx] - pose[2 * 4 + 3]);

                camera_z[idx] = pose[0 * 4 + 2] * (world_x[idx] - pose[0 * 4 + 3]) +
                    pose[1 * 4 + 2] * (world_y[idx] - pose[1 * 4 + 3]) +
                    pose[2 * 4 + 2] * (world_z[idx] - pose[2 * 4 + 3]);

                if (camera_z[idx] <= 0) {
                    valid_point[idx] = false;
                    --valid_num;
                }
            }
            if (camera_z[0] <= 0) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 rgb
        if (update_rgb || update_label || update_instance) {
            for (size_t idx = 0; idx < d_sub_point_num; ++idx) {
                if (!valid_point[idx]) continue;

                rgb_x[idx] = roundf(d_rgb_intrinsics[0 * 3 + 0] * (camera_x[idx] / camera_z[idx]) + d_rgb_intrinsics[0 * 3 + 2]);
                rgb_y[idx] = roundf(d_rgb_intrinsics[1 * 3 + 1] * (camera_y[idx] / camera_z[idx]) + d_rgb_intrinsics[1 * 3 + 2]);

                if (rgb_x[idx] < 0 || rgb_x[idx] >= d_rgb_width || rgb_y[idx] < 0 || rgb_y[idx] >= d_rgb_height) {
                    valid_point[idx] = false;
                    --valid_num;
                    continue;
                }

                int color_index = (rgb_y[idx] * d_rgb_width + rgb_x[idx]) * 3;
                b_current[idx] = rgb_image[color_index + 0];
                g_current[idx] = rgb_image[color_index + 1];
                r_current[idx] = rgb_image[color_index + 2];
            }
            if (rgb_x[0] < 0 || rgb_x[0] >= d_rgb_width || rgb_y[0] < 0 || rgb_y[0] >= d_rgb_height) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 panoptic
        if (update_label || update_instance) {
            for (size_t idx = 0; idx < d_sub_point_num; ++idx) {
                if (!valid_point[idx]) continue;

                panoptic_x[idx] = rgb_x[idx];
                panoptic_y[idx] = rgb_y[idx];

                int panoptic_index = (panoptic_y[idx] * d_panoptic_width + panoptic_x[idx]) * 3;
                instance_current[idx] = panoptic_image[panoptic_index + 0];
                label_current[idx] = panoptic_image[panoptic_index + 1];
                label_weight_current[idx] = panoptic_image[panoptic_index + 2];
            }

            if (label_weight_current[0] == 0.0f) update_label = false;
        }

        // 计算 depth
        if (update_rgb || update_label || update_instance) {
            for (size_t idx = 0; idx < d_sub_point_num; ++idx) {
                if (!valid_point[idx]) continue;

                depth_x[idx] = roundf(d_depth_intrinsics[0 * 3 + 0] * (camera_x[idx] / camera_z[idx]) + d_depth_intrinsics[0 * 3 + 2]);
                depth_y[idx] = roundf(d_depth_intrinsics[1 * 3 + 1] * (camera_y[idx] / camera_z[idx]) + d_depth_intrinsics[1 * 3 + 2]);
                if (depth_x[idx] < 0 || depth_x[idx] >= d_depth_width || depth_y[idx] < 0 || depth_y[idx] >= d_depth_height) {
                    valid_point[idx] = false;
                    --valid_num;
                    continue;
                }

                depth[idx] = depth_image[depth_y[idx] * d_depth_width + depth_x[idx]];
                if (depth[idx] <= 0 || depth[idx] >= 10) {
                    valid_point[idx] = false;
                    --valid_num;
                }
            }

            if (depth_x[0] < 0 || depth_x[0] >= d_depth_width || depth_y[0] < 0 || depth_y[0] >= d_depth_height || depth[0] <= 0 || depth[0] >= 10) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 best 值
        if (update_rgb || update_label || update_instance) {

            best_r_current = r_current[0];
            best_g_current = g_current[0];
            best_b_current = b_current[0];

            best_label_current = GetMajorityLabel(valid_point, label_current, d_sub_point_num);
            //best_label_current = label_current[0];

            best_instance_current = instance_current[0];

            //best_label_weight_current = label_weight_current[0];
            best_label_weight_current = GetAverageLabelWeightByLabel(valid_point, label_weight_current, label_current, d_sub_point_num, best_label_current);

            best_diff = depth[0] - camera_z[0];
            //best_diff = GetAverageDiffByLabel(valid_point, depth, camera_z, label_current, d_sub_point_num, best_label_current);

            if (best_diff <= -d_trunc_margin) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
            else {
                best_dist = fmin(1.0f, best_diff / d_trunc_margin);   // 对 sdf 进行截断 错误
            }
        }

#else
        int rgb_x, rgb_y, depth_x, depth_y, panoptic_x, panoptic_y;
        float depth, dist;
        float camera_x, camera_y, camera_z;

        
        // 计算坐标
        if (update_rgb || update_label || update_instance) {
            /*
             Convert from base frame camera coordinates to current frame camera coordinates
             define: 相机位姿矩阵 = 相机外参，相机坐标 = 相机位姿 * 世界坐标
             世界坐标 -> 相机坐标
             base frame 是相机的初始坐标，根据相机的当前位姿，投影到相机的当前坐标
             此时，就可以得到该体素到相机的距离 pt_cam_z
             世界坐标 -> 相机坐标
             旋转矩阵的逆等于转置
             dimension: m
            */
            float world_x = d_origin_x + d_grid_size * threadIdx.x;
            float world_y = d_origin_y + d_grid_size * blockIdx.x;
            float world_z = d_origin_z + d_grid_size * blockIdx.y;

            camera_x = pose[0 * 4 + 0] * (world_x - pose[0 * 4 + 3]) +
                pose[1 * 4 + 0] * (world_y - pose[1 * 4 + 3]) +
                pose[2 * 4 + 0] * (world_z - pose[2 * 4 + 3]);

            camera_y = pose[0 * 4 + 1] * (world_x - pose[0 * 4 + 3]) +
                pose[1 * 4 + 1] * (world_y - pose[1 * 4 + 3]) +
                pose[2 * 4 + 1] * (world_z - pose[2 * 4 + 3]);

            camera_z = pose[0 * 4 + 2] * (world_x - pose[0 * 4 + 3]) +
                pose[1 * 4 + 2] * (world_y - pose[1 * 4 + 3]) +
                pose[2 * 4 + 2] * (world_z - pose[2 * 4 + 3]);   // 正确

            if (camera_z <= 0) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 rgb
        if (update_rgb || update_label || update_instance) {
            rgb_x = roundf(d_rgb_intrinsics[0 * 3 + 0] * (camera_x / camera_z) + d_rgb_intrinsics[0 * 3 + 2]);  //正确
            rgb_y = roundf(d_rgb_intrinsics[1 * 3 + 1] * (camera_y / camera_z) + d_rgb_intrinsics[1 * 3 + 2]);

            panoptic_x = rgb_x;
            panoptic_y = rgb_y;

            if (rgb_x < 0 || rgb_x >= d_rgb_width || rgb_y < 0 || rgb_y >= d_rgb_height) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
            else {
                int color_index = (rgb_y * d_rgb_width + rgb_x) * 3;
                best_b_current = rgb_image[color_index + 0];
                best_g_current = rgb_image[color_index + 1];
                best_r_current = rgb_image[color_index + 2];
            }
        }

        // 计算 depth
        if (update_rgb || update_label || update_instance) {
            // 相机坐标 -> depth 像素坐标
            depth_x = roundf(d_depth_intrinsics[0 * 3 + 0] * (camera_x / camera_z) + d_depth_intrinsics[0 * 3 + 2]);
            depth_y = roundf(d_depth_intrinsics[1 * 3 + 1] * (camera_y / camera_z) + d_depth_intrinsics[1 * 3 + 2]);

            if (depth_x < 0 || depth_x >= d_depth_width || depth_y < 0 || depth_y >= d_depth_height) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
            else {
                depth = depth_image[depth_y * d_depth_width + depth_x];
            }

            if (depth <= 0 || depth >= 10) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
        }

        // 计算 panoptic
        if (update_label || update_instance) {
            int panoptic_index = (panoptic_y * d_panoptic_width + panoptic_x) * 3;
            best_instance_current = (int)panoptic_image[panoptic_index + 0];
            best_label_current = (int)panoptic_image[panoptic_index + 1];
            best_label_weight_current = panoptic_image[panoptic_index + 2];

            if (best_label_weight_current == 0.0f) update_label = false;
        }

        // 计算 best 值
        if (update_rgb || update_label || update_instance) {
            best_diff = (depth - camera_z);

            if (best_diff <= -d_trunc_margin) {
                update_rgb = false;
                update_label = false;
                update_instance = false;
            }
            else {
                best_dist = fmin(1.0f, best_diff / d_trunc_margin);
            }
        }
        
#endif
        
        // 更新 rgb 和 tsdf
        if (update_rgb) {
            float rgb_weight_old = bgr_weight[voxel_index];
            float rgb_weight_new = rgb_weight_old + 1.0f;

            float b_old = color_b[voxel_index];
            float g_old = color_g[voxel_index];
            float r_old = color_r[voxel_index];

            float b_new = (b_old * rgb_weight_old + best_b_current) / rgb_weight_new;
            float g_new = (g_old * rgb_weight_old + best_g_current) / rgb_weight_new;
            float r_new = (r_old * rgb_weight_old + best_r_current) / rgb_weight_new;

            color_b[voxel_index] = b_new;
            color_g[voxel_index] = g_new;
            color_r[voxel_index] = r_new;
            bgr_weight[voxel_index] = rgb_weight_new;

            float tsdf_old = tsdf[voxel_index];
            float tsdf_new = (tsdf_old * rgb_weight_old + best_dist) / rgb_weight_new;

            tsdf[voxel_index] = tsdf_new;
        }

        // 更新 label
        if (update_label) {
            int label_old = label[voxel_index];
            float label_weight_old = label_weight[voxel_index];

            int label_new;
            float label_weight_new;

            if (label_old == -1) {
                label_new = best_label_current;
                label_weight_new = 1.0f;
            }
            else {
                if (best_label_current == label_old) label_weight_new = label_weight_old + 1.0f;
                else label_weight_new = label_weight_old - 1.0f;

                if (label_weight_new >= 0) label_new = label_old;
                else label_new = best_label_current;
            }

            label[voxel_index] = label_new;
            label_weight[voxel_index] = label_weight_new;
        }

        // 更新 instance
        if (update_instance) {

        }
    }

    __device__ void UpdateGl(const int voxel_index, float* color_b, float* color_g, float* color_r, int* instance, int* label_list, float* tsdf, float* bgr_weight, float* label_weight, float* instance_weight,
        float* pose, float* rgb_image, float* depth_image, float* panoptic_image,
        float* gl_rgb, float* gl_label, float* gl_instance, unsigned int* gl_point_num) {

        float x = d_origin_x + d_grid_size * threadIdx.x;
        float y = d_origin_y + d_grid_size * blockIdx.x;
        float z = d_origin_z + d_grid_size * blockIdx.y;

        if (abs(tsdf[voxel_index]) >= 0.2f) return;
        // 显示 rgb
        if (bgr_weight[voxel_index] > 0.0f) {

            int idx = atomicInc(gl_point_num, UINT_MAX);
            gl_rgb[idx * 6 + 0] = x;
            gl_rgb[idx * 6 + 1] = y;
            gl_rgb[idx * 6 + 2] = z;
            gl_rgb[idx * 6 + 3] = color_r[voxel_index];
            gl_rgb[idx * 6 + 4] = color_g[voxel_index];
            gl_rgb[idx * 6 + 5] = color_b[voxel_index];

            float label_r, label_g, label_b;
            int label = label_list[voxel_index];

            if (label == 0) { label_r = 174; label_g = 199; label_b = 232; }
            else if (label == 1) { label_r = 152; label_g = 223; label_b = 138; }
            else if (label == 2) { label_r = 31; label_g = 119; label_b = 180; }
            else if (label == 3) { label_r = 255; label_g = 187; label_b = 120; }
            else if (label == 4) { label_r = 188; label_g = 189; label_b = 34; }
            else if (label == 5) { label_r = 140; label_g = 86; label_b = 75; }
            else if (label == 6) { label_r = 255; label_g = 152; label_b = 150; }
            else if (label == 7) { label_r = 214; label_g = 39; label_b = 40; }
            else if (label == 8) { label_r = 197; label_g = 176; label_b = 213; }
            else if (label == 9) { label_r = 148; label_g = 103; label_b = 189; }
            else if (label == 10) { label_r = 196; label_g = 156; label_b = 148; }
            else if (label == 11) { label_r = 23; label_g = 190; label_b = 207; }
            else if (label == 12) { label_r = 178; label_g = 76; label_b = 76; }
            else if (label == 13) { label_r = 247; label_g = 182; label_b = 210; }
            else if (label == 14) { label_r = 66; label_g = 188; label_b = 102; }
            else if (label == 15) { label_r = 219; label_g = 219; label_b = 141; }
            else if (label == 16) { label_r = 140; label_g = 57; label_b = 197; }
            else if (label == 17) { label_r = 202; label_g = 185; label_b = 52; }
            else if (label == 18) { label_r = 51; label_g = 176; label_b = 203; }
            else if (label == 19) { label_r = 200; label_g = 54; label_b = 131; }
            else if (label == 20) { label_r = 92; label_g = 193; label_b = 61; }
            else if (label == 21) { label_r = 78; label_g = 71; label_b = 183; }
            else if (label == 22) { label_r = 172; label_g = 114; label_b = 82; }
            else if (label == 23) { label_r = 255; label_g = 127; label_b = 14; }
            else if (label == 24) { label_r = 91; label_g = 163; label_b = 138; }
            else if (label == 25) { label_r = 153; label_g = 98; label_b = 156; }
            else if (label == 26) { label_r = 140; label_g = 153; label_b = 101; }
            else if (label == 27) { label_r = 158; label_g = 218; label_b = 229; }
            else if (label == 28) { label_r = 100; label_g = 125; label_b = 154; }
            else if (label == 29) { label_r = 178; label_g = 127; label_b = 135; }
            else if (label == 30) { label_r = 120; label_g = 185; label_b = 128; }
            else if (label == 31) { label_r = 146; label_g = 111; label_b = 194; }
            else if (label == 32) { label_r = 44; label_g = 160; label_b = 44; }
            else if (label == 33) { label_r = 112; label_g = 128; label_b = 144; }
            else if (label == 34) { label_r = 96; label_g = 207; label_b = 209; }
            else if (label == 35) { label_r = 227; label_g = 119; label_b = 194; }
            else if (label == 36) { label_r = 213; label_g = 92; label_b = 176; }
            else if (label == 37) { label_r = 94; label_g = 106; label_b = 211; }
            else if (label == 38) { label_r = 82; label_g = 84; label_b = 163; }
            else if (label == 39) { label_r = 100; label_g = 85; label_b = 144; }
            else { label_r = 0.0f; label_g = 0.0f; label_b = 0.0f; }

            gl_label[idx * 6 + 0] = x;
            gl_label[idx * 6 + 1] = y;
            gl_label[idx * 6 + 2] = z;
            gl_label[idx * 6 + 3] = label_r / 255.0f;
            gl_label[idx * 6 + 4] = label_g / 255.0f;
            gl_label[idx * 6 + 5] = label_b / 255.0f;

        }

        // 显示 instance
    }

    __device__ int GetLeft(int x_index, int x_num) { return (blockIdx.x * blockDim.x + threadIdx.x) * x_num + x_index - 1; }

    __device__ int GetRight(int x_index, int x_num) { return (blockIdx.x * blockDim.x + threadIdx.x) * x_num + x_index + 1; }

    __device__ int GetUp(int x_index, int x_num) { return (blockIdx.x * blockDim.x + threadIdx.x + 1) * x_num + x_index; }

    __device__ int GetDown(int x_index, int x_num) { return (blockIdx.x * blockDim.x + threadIdx.x - 1) * x_num + x_index; }

    __device__ int GetFront(int x_index, int x_num) { return ((blockIdx.x + 1) * blockDim.x + threadIdx.x) * x_num + x_index; }

    __device__ int GetBehind(int x_index, int x_num) { return ((blockIdx.x - 1) * blockDim.x + threadIdx.x) * x_num + x_index; }

    __device__ float GetMajorityLabel(bool valid_point[], float list[], int len) {
        float majority_label;
        int count[27];
        int num = 0;
        for (size_t i = 0; i < len; ++i) {
            if (!valid_point[i]) continue;
            ++count[int(list[i])];
            if (count[int(list[i])] > num) {
                num = count[int(list[i])];
                majority_label = list[i];
            }
        }
        return majority_label;
    }

    __device__ float GetAverageDiffByLabel(bool valid_point[], float depth_list[], float camera_z_list[], float label_list[], int len, float label) {
        float average_diff = 0.0f;
        int num = 0;
        for (size_t i = 0; i < len; ++i) {
            if (valid_point[i] && label_list[i] == label) {
                average_diff += (depth_list[i] - camera_z_list[i]);
                ++num;
            }
        }
        return average_diff / float(num);
    }

    __device__ float GetMajorityLabelWeightByLabel(bool valid_point[], float label_weight_list[], float label_list[], int len, float label) {
        float majority_label_weight;
        int count[27];
        int num = 0;
        for (size_t i = 0; i < len; ++i) {
            if (valid_point[i] && label_list[i] == label) {
                ++count[int(label_weight_list[i])];
                if (count[int(label_weight_list[i])] > num) {
                    num = count[int(label_weight_list[i])];
                    majority_label_weight = label_weight_list[i];
                }
            }
        }
        return majority_label_weight;
    }

    __device__ float GetAverageLabelWeightByLabel(bool valid_point[], float label_weight_list[], float label_list[], int len, float label) {
        float average_label_weight;
        int num = 0;
        for (size_t i = 0; i < len; ++i) {
            if (valid_point[i] && label_list[i] == label) {
                average_label_weight += label_weight_list[i];
                ++num;
            }
        }
        return average_label_weight / float(num);
    }

}