#ifndef JIAMERA_PARTICLES_H_
#define JIAMERA_PARTICLES_H_

#include <iostream>
#include <string>
// #include <glm/gtc/matrix_transform.hpp>
// #include <glm/gtc/type_ptr.hpp>
// #include <glad/glad.h>

#include <glad/glad.h>
#include <GL/gl.h>
#include <GL/glut.h>
#include <GLFW/glfw3.h>
#include <GL/glu.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

// #include "cuda_gl_interop.h"
#include "Object.h"
#include "Camera.h"
#include "Gui.h"
#include "Window.h"
#include "Voxel.h"

float axis[36] = {
	0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, // 原点
	5.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, // x

	0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, // 原点
	0.0f, 5.0f, 0.0f, 0.0f, 1.0f, 0.0f, // y

	0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, // 原点
	0.0f, 0.0f, 5.0f, 0.0f, 0.0f, 1.0f, // z
};

namespace Jiamera {

	class Particles : public Voxel {

	public:
		Particles(float x, float y, float z, float size) : Voxel(x, y, z, size) {
			std::cout << "Creating Particles Class -----------------------------------------\n";
		}

		Particles(const Particles&) = delete;
		Particles& operator=(const Particles&) = delete;

		void Display(GLFWwindow* const window, 
			         const unsigned int window_idx) override {

			Shader point_shader_("Shader1.vs", "Shader1.fs");

			//创建VBO和VAO对象，并赋予ID
			unsigned int VBO[2], VAO[2];
			// cudaGraphicsResource* d_VBO[2];
			// cudaGraphicsResource* d_VAO[2];

			glGenVertexArrays(2, VAO);
			glGenBuffers(2, VBO);

			/*初始化坐标轴数组*/
			{
				glBindVertexArray(VAO[0]);
				glBindBuffer(GL_ARRAY_BUFFER, VBO[0]);

				glBufferData(GL_ARRAY_BUFFER, sizeof(axis), 
					         axis, GL_STATIC_DRAW);

				glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 
					                  6 * sizeof(float), (void*)0);
				glEnableVertexAttribArray(0);

				glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 
					                  6 * sizeof(float), 
					                  (void*)(3 * sizeof(float)));

				glEnableVertexAttribArray(1);

				glBindBuffer(GL_ARRAY_BUFFER, 0);
				glBindVertexArray(0);
			}

			size_t current_point_num_ = 0;

			/*初始化点云数组*/
			{
				//绑定VBO和VAO对象
				glBindVertexArray(VAO[1]);
				glBindBuffer(GL_ARRAY_BUFFER, VBO[1]);

				/*设置 position*/
				// 第1个参数指定要配置的顶点属性，与 layout (location = 0) 
				// 定义了 position 顶点属性的位置值对应
				// 第2个参数指定顶点属性的大小。顶点属性是一个vec3，它由3个值组成
				// 第5个参数表示每个点包含的存储空间大小，而不是数组总长度
				glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
				glEnableVertexAttribArray(0);

				/*设置 color*/
				glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
				glEnableVertexAttribArray(1);

				glBindBuffer(GL_ARRAY_BUFFER, 0);
				glBindVertexArray(0);
			}

			while (!glfwWindowShouldClose(window)) {

				if (window == rgb_window) {
					float currentFrame = static_cast<float>(glfwGetTime());
					deltaTime = currentFrame - lastFrame;
					lastFrame = currentFrame;
				}

				processInput(window);
				glClearColor(1.0f, 1.0f, 1.0f, 1.0f); //状态设置
				glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

				// 刷新相机位姿
				{
					point_shader_.use();
					glm::mat4 projection =
						glm::perspective(glm::radians(universal_camera.Zoom),
							(float)SCR_WIDTH / (float)SCR_HEIGHT,
							0.1f, 50.0f);
					point_shader_.setMat4("projection", projection);

					glm::mat4 view = universal_camera.GetViewMatrix();
					point_shader_.setMat4("view", view);

					// make sure to initialize matrix to identity matrix first
					glm::mat4 model = glm::mat4(1.0f);
					point_shader_.setMat4("model", model);
				}


				// 点云数组 (CPU 更新)
				{
#ifndef GPU_UPDATE_GL_

					glBindVertexArray(VAO[1]);
					glBindBuffer(GL_ARRAY_BUFFER, VBO[1]);

					glPointSize(4.0f);
					glDrawArrays(GL_POINTS, 0, current_point_num_);	// mode first count

					if (gl_data_mtx_.try_lock_shared()) {	// 尝试抢占读锁

						int idx = window_idx;
						if (thread_atom.compare_exchange_strong(idx, idx - 1)) {	 // 若轮到本线程读取
							//if (thread_atom.load() > 0) {
							current_point_num_ = gl_point_num_;

							// 在此修改显示的属性
							if (idx == 1) {		// rgb  窗口
								glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 6 * current_point_num_, this->gl_rgb_, GL_STATIC_DRAW);
							}
							else if (idx == 2) {	// label 窗口
								glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 6 * current_point_num_, this->gl_label_, GL_STATIC_DRAW);
							}
							else {		// instance 窗口
								glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 6 * current_point_num_, this->gl_instance_, GL_STATIC_DRAW);
							}
							//thread_atom.fetch_sub(1);
						}
						gl_data_mtx_.unlock_shared();
					}
					glBindBuffer(GL_ARRAY_BUFFER, 0);
					glBindVertexArray(0);

#else
					glBindVertexArray(VAO[1]);

					if (gl_data_mtx_.try_lock_shared()) {	// 尝试抢占读锁
						int idx = window_idx;
						if (thread_atom.compare_exchange_strong(idx, idx - 1)) {	 // 若轮到本线程读取
							current_point_num_ = gl_point_num_;
						}
						gl_data_mtx_.unlock_shared();

						glBindBuffer(GL_ARRAY_BUFFER, VBO[1]);
						glBufferData(GL_ARRAY_BUFFER, sizeof(float) * current_point_num_ * this->attrib_num_, nullptr, GL_STATIC_DRAW);
						cudaGraphicsGLRegisterBuffer(&d_VBO[1], VBO[1], cudaGraphicsRegisterFlagsReadOnly);
						glBindBuffer(GL_ARRAY_BUFFER, 0);
					}

					if (current_point_num_ > 0) {
						printf("%d %d %%%%%%%%%%%%\n", current_point_num_, gl_point_num_);
						//if (cudaSuccess != cudaMemcpy(d_gl_data2, d_gl_data1, /*sizeof(float) * current_point_num_ * this->attrib_num_*/1, cudaMemcpyDeviceToDevice)) printf("d_gl_data MemcpyDeviceToDevice error.\n");

						size_t size = current_point_num_ * this->attrib_num_ * sizeof(float);
						cudaGraphicsMapResources(1, &d_VBO[1], 0);
						cudaGraphicsResourceGetMappedPointer((void**)&d_gl_data2, &size, d_VBO[1]);
						cudaGraphicsUnmapResources(1, &d_VBO[1], 0);

						glPointSize(4.0f);
						glDrawArrays(GL_POINTS, 0, current_point_num_);	// mode first count
					}

					glBindVertexArray(0);
#endif

				}
				
				// 坐标轴
				{	
					glBindVertexArray(VAO[0]);
					glBindBuffer(GL_ARRAY_BUFFER, VBO[0]);
					//glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, axis_EBO);

					glPointSize(4.0f);
					glDrawArrays(GL_LINES, 0, 6);	// 点的个数，而不是线的个数

					//glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
					glBindBuffer(GL_ARRAY_BUFFER, 0);
					glBindVertexArray(0);

				}

				glfwSwapBuffers(window);
				glfwPollEvents();
			}

			// glfw: 回收前面分配的GLFW先关资源. 
			glDeleteVertexArrays(1, VAO);
			glDeleteBuffers(1, VBO);
			//glDeleteProgram(point_shader_.ID);
		}


	};

}

#endif // JIAMERA_PARTICLES_H_